
module GremlinClient
  # represents the connection to our gremlin server
  class Connection

    attr_reader :timeout, :groovy_script_path

    # initialize a new connection using:
    #   host    => hostname/ip where to connect
    #   port    => listen port of the server
    #   timeout => how long the client might wait for response from the server
    def initialize(
      host: 'localhost',
      port: 8182,
      timeout: 10,
      groovy_script_path: '.'
    )
      url = "ws://#{host}:#{port}"

      gremlin = self
      WebSocket::Client::Simple.connect("ws://#{host}:#{port}/") do |ws|
        @ws = ws

        @ws.on :message do |msg|
          gremlin.receive_message(msg)
          @response=msg
        end

        @ws.on :error do |e|
          receive_error(e)
        end
      end


      @timeout = timeout
      @groovy_script_path = groovy_script_path
    end


    def send(command, bindings={})
      wait_connection
      reset_timer
      @ws.send(build_message(command, bindings), { type: 'text' })
      wait_response
      return parse_response
    end

    def send_file(filename, bindings={})
      send(IO.read(resolve_path(filename)), bindings)
    end

    def open?
      @ws.open?
    end

    def close
      @ws.close
    end


    # this has to be public so the websocket client thread sees it
    def receive_message(msg)
      @response = JSON.parse(msg.data)
    end

    def receive_error(e)
      @error = e
    end

    protected

      def wait_connection(w_timeout = 1)
        w_from = Time.now.to_i
        while !open? && Time.now.to_i - w_timeout < w_from
          sleep 0.001
        end
      end

      def reset_timer
        @started_at = Time.now.to_i
        @error = nil
        @response = nil
      end

      def wait_response
        while @response.nil? and @error.nil? && (Time.now.to_i - @started_at < @timeout)
          sleep 0.001
        end

        fail ::GremlinClient::ServerError.new(nil, @error) unless @error.nil?
        fail ::GremlinClient::ExecutionTimeoutError.new(@timeout) if @response.nil?
      end

      # we validate our response here to make sure it is going to be
      # raising exceptions in the right thread
      def parse_response
        unless @response['status']['code'] == 200
          fail ::GremlinClient::ServerError.new(@response['status']['code'], @response['status']['message'])
        end
        @response['result']
      end

      def build_message(command, bindings)
        message = {
          requestId: SecureRandom.uuid,
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
        "#{@groovy_script_path}/#{filename}"
      end
  end
end
