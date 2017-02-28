
module GremlinClient
  # to track error of timeout executing a specific query
  class ExecutionTimeoutError < StandardError
    attr_reader :timeout
    def initialize(timeout)
      @timeout = timeout
    end
    def to_s
      "#{@timeout}s"
    end
  end
end
