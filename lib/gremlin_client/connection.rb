
module GremlinClient
  # represents the connection to our gremlin server
  class Connection

    # initialize a new connection using:
    #   host    => hostname/ip where to connect
    #   port    => listen port of the server
    #   timeout => how long the client might wait for response from the server
    def initialize(
      host: 'localhost',
      port: 8182,
      timeout: 10
    )
      url = "ws://#{host}:#{port}"
      WebSocket::Client::Simple.connect("ws://#{host}:#{port}/") do |ws|
        @ws = ws

        @ws.on :message do |msg|
          puts "omgomgom"
          pp msg
          @response=msg
        end

        @ws.on :error do |e|
          puts 'om'
          pp e
          puts "omup"
          receive_error(e)
        end

        @ws.on :open do
          puts 'connect'
        end

        @ws.on :close do
          puts 'closing'
        end
      end


      @timeout = timeout
      # to give time to connect
      sleep 0.2
    end


    def send(command)
      reset_timer
      unless open?
        fail "not open yet"
      end
      @ws.send(build_message(command), { type: 'text' })
      wait_response
      return @response
    end

    def open?
      @ws.open?
    end

    def close
      @ws.close
    end



    protected
      def reset_timer
        @started_at = Time.now.to_i
        @response = nil
      end

      def wait_response
        while @response.nil? and (Time.now.to_i - @started_at < @timeout)
          sleep 0.1
        end

        fail "Timeout!" if @response.nil?
      end

      def receive_message(msg)
        @response = msg
      end

      def receive_error(e)
        raise "Received error: #{e}"
      end

      def build_message(command)
        message = {
          requestId: SecureRandom.uuid,
          op: 'eval',
          processor: '',
          args: {
            gremlin: command,
            bindings: {},
            language: 'gremlin-groovy'
          }
        }
        puts JSON.generate(message)
        JSON.generate(message)
      end

  end
end
