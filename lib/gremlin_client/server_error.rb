
module GremlinClient
  class ServerError < StandardError
    def initialize(code, message)
      @code = code
      @message = message
    end

    def to_s
      "#{@message} (code #{@code})"
    end
  end
end
