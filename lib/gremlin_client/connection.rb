
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
      timeout: 1000
    )
      @ws = WebSocket::Client::Simple.connect("ws://#{host}:#{port}")

      @ws.on :message do |msg|
        puts "omgomgom"
        receive_message(msg)
      end

      @ws.on :error do |e|
        receive_error(e)
      end

      @ws.on :open do
        puts 'connect'
      end

      @timeout = timeout

      pp @ws
    end


    def send(command)
      reset_timer
      @ws.send(command)
      wait_response
      return @response
    end



    protected
      def reset_timer
        @started_at = Time.now
        @response = nil
      end

      def wait_response
        while @response.nil? and (Time.now - @started_at > @timeout)
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

  end
end
