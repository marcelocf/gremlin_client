
module GremlinClient
  # To process error messages coming from the server
  class ServerError < StandardError
    attr_reader :message, :code
    def initialize(code, message)
      @code = code
      @message = message
    end

    def to_s
      "#{@message} (code #{@code})"
    end
  end
end
