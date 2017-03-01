# frozen_string_literal: true

require 'spec_helper'

# Tests on the freetext feature
RSpec.describe :status_codes do
  it :declared_every_code do
    {
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
    }.each_pair do |key, code|
      expect(GremlinClient::Connection::STATUS[key]).to eq(code)
    end
  end

  it :doesnt_have_extra_codes do
    expect(GremlinClient::Connection::STATUS.count).to be(11)
  end
end
