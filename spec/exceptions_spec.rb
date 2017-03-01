
# frozen_string_literal: true

require 'spec_helper'

# test on formating messages from exceptions
RSpec.describe :exceptions do
  it :connection_timeout_error do
    expect(::GremlinClient::ConnectionTimeoutError.new(10).to_s).to eq('10s')
    expect(::GremlinClient::ConnectionTimeoutError.new(1).to_s).to eq('1s')
    expect(::GremlinClient::ConnectionTimeoutError.new(1123).to_s).to eq('1123s')
  end

  it :execution_timeout_error do
    expect(::GremlinClient::ExecutionTimeoutError.new(10).to_s).to eq('10s')
    expect(::GremlinClient::ExecutionTimeoutError.new(1).to_s).to eq('1s')
    expect(::GremlinClient::ExecutionTimeoutError.new(1123).to_s).to eq('1123s')
  end

  it :server_error do
    expect(::GremlinClient::ServerError.new(:code, :message).to_s).to eq('message (code code)');
    expect(::GremlinClient::ServerError.new(312, 'this exploded here').to_s).to eq('this exploded here (code 312)');
  end
end
 
