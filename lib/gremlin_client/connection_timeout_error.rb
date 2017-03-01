
module GremlinClient
  # to track error of timeout while waiting for connection
  class ConnectionTimeoutError < StandardError
    attr_reader :timeout
    def initialize(timeout)
      @timeout = timeout
    end
    def to_s
      "#{@timeout}s"
    end
  end
end
