
module GremlinClient
  # represents the connection to our gremlin server
  class Connection

    attr_reader :connection_timeout, :timeout, :gremlin_script_path

    STATUS = {
      success: 200,
      no_content: 204,
      partial_content: 206,

      unauthorized: 401,
      authenticate: 407,
      malformed_request: 498,
      invalid_request_arguments: 499,
      server_error: 500,
      script_evaluation_error: 597,
      server_timeout: 598,
      server_serialization_error: 599
    }

    class << self
      # a centralized place for you to store a connection pool of those objects
      # recommendeded one is: https://github.com/mperham/connection_pool
      attr_accessor :pool
    end

    # initialize a new connection using:
    #   host    => hostname/ip where to connect
    #   port    => listen port of the server
    #   timeout => how long the client might wait for response from the server
    def initialize(
      host: 'localhost',
      port: 8182,
      connection_timeout: 1,
      timeout: 10,
      gremlin_script_path: '.',
      autoconnect: true
    )
      @host = host
      @port = port
      @connection_timeout = connection_timeout
      @timeout = timeout
      @gremlin_script_path = gremlin_script_path
      @gremlin_script_path = Pathname.new(@gremlin_script_path) unless @gremlin_script_path.is_a?(Pathname)
      @autoconnect = autoconnect
      connect if @autoconnect
    end

    # creates a new connection object
    def connect
      gremlin = self
      WebSocket::Client::Simple.connect("ws://#{@host}:#{@port}/") do |ws|
        @ws = ws

        @ws.on :message do |msg|
          gremlin.receive_message(msg)
        end

        @ws.on :error do |e|
          receive_error(e)
        end
      end
    end

    def reconnect
      @ws.close unless @ws.nil?
      connect
    end

    def send_query(command, bindings={})
      wait_connection
      reset_request
      @ws.send(build_message(command, bindings), { type: 'text' })
      wait_response
      return treat_response
    end

    def send_file(filename, bindings={})
      send_query(IO.read(resolve_path(filename)), bindings)
    end

    def open?
      @ws.open?
    rescue ::NoMethodError
      # #2 => it appears to happen in some situations when the situation is dropped
      return false
    end

    def close
      @ws.close
    end


    # this has to be public so the websocket client thread sees it
    def receive_message(msg)
      response = JSON.parse(msg.data)
      # this check is important in case a request timeout and we make new ones after
      if response['requestId'] == @request_id
        if @response.nil?
          @response = response
        else
          @response['result']['data'].concat response['result']['data']
          @response['result']['meta'].merge! response['result']['meta']
          @response['status'] = response['status']
        end
      end
    end

    def receive_error(e)
      @error = e
    end

    protected

      def wait_connection(skip_reconnect = false)
        w_from = Time.now.to_i
        while !open? && Time.now.to_i - @connection_timeout < w_from
          sleep 0.001
        end
        unless open?
          # reconnection code
          if @autoconnect && !skip_reconnect
            reconnect
            return wait_connection(true)
          end
          fail ::GremlinClient::ConnectionTimeoutError.new(@connection_timeout)
        end
      end

      def reset_request
        @request_id= SecureRandom.uuid
        @started_at = Time.now.to_i
        @status = nil
        @error = nil
        @response = nil
      end

      def is_finished?
        return false if @response.nil? && @error.nil?
        return @response['status']['code'] != STATUS[:partial_content]
      end

      def wait_response
        while !is_finished? && (Time.now.to_i - @started_at < @timeout)
          sleep 0.001
        end

        fail ::GremlinClient::ServerError.new(nil, @error) unless @error.nil?
        fail ::GremlinClient::ExecutionTimeoutError.new(@timeout) if @response.nil?
      end

      # we validate our response here to make sure it is going to be
      # raising exceptions in the right thread
      def treat_response
        # note that the partial_content status should be processed differently.
        # look at http://tinkerpop.apache.org/docs/3.0.1-incubating/ for more info
        ok_status = [:success, :no_content, :partial_content].map { |st| STATUS[st] }
        unless ok_status.include?(@response['status']['code'])
          fail ::GremlinClient::ServerError.new(@response['status']['code'], @response['status']['message'])
        end
        @response['result']
      end

      def build_message(command, bindings)
        message = {
          requestId: @request_id,
          op: 'eval',
          processor: '',
          args: {
            gremlin: command,
            bindings: bindings,
            language: 'gremlin-groovy'
          }
        }
        JSON.generate(message)
      end

      def resolve_path(filename)
        return filename if filename.is_a?(String) && filename[0,1] == '/'
        @gremlin_script_path.join(filename).to_s
      end
  end
end
