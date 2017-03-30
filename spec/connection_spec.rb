
# frozen_string_literal: true

require 'spec_helper'

# Tests on the freetext feature
RSpec.describe :connection do
  class MockedSocket
    def close
      nil
    end
  end

  module Message
    def self.status=(name)
      @status_code = GremlinClient::Connection::STATUS[name]
    end

    def self.request_id=(requestId)
      @request_id = requestId
    end

    def self.called=(c)
      @called = c
    end

    def self.data
      @called ||= 0
      @called += 1
      #rid = ", \"requestId\" : \"#{@request_id}\"" unless @request_id.nil?
      #stt = ", \"status\" : { \"code\" : #{@status_code} }" unless @status_code.nil?
      #"{\'{\"example\" : \"data #{@called}\"#{rid}#{stt}}"
      {
        requestId: @request_id,
        status: { code: @status_code },
        result: {
          data: [@called],
          meta: {},
        },
      }.to_json
    end
  end

  before do
    sock = MockedSocket.new
    allow(sock).to receive(:on).and_yield(Message)
    allow(WebSocket::Client::Simple).to receive(:connect).and_yield(sock)
  end

  describe :initialize do
    it :websocket do
      expect(WebSocket::Client::Simple).to receive(:connect).with('ws://localhost:8182/')
      conn = GremlinClient::Connection.new
    end

    it :websocket do
      expect(WebSocket::Client::Simple).to receive(:connect).with('ws://SERVER_A:123/')
      conn = GremlinClient::Connection.new(host: :SERVER_A, port: 123)
    end

    it :gremlin_script_path do
      conn = GremlinClient::Connection.new
      expect(conn.gremlin_script_path).to eq(Pathname.new('.'))
      conn = GremlinClient::Connection.new(gremlin_script_path: '/etc/groovy')
      expect(conn.gremlin_script_path).to eq(Pathname.new('/etc/groovy'))
    end

    it :connection_timeout do
      conn = GremlinClient::Connection.new
      expect(conn.connection_timeout).to eq(1)
      conn = GremlinClient::Connection.new(connection_timeout: 11)
      expect(conn.connection_timeout).to eq(11)
    end

    it :timeout do
      conn = GremlinClient::Connection.new
      expect(conn.timeout).to eq(10)
      conn = GremlinClient::Connection.new(timeout: 1)
      expect(conn.timeout).to eq(1)
    end


    it :socket_listeners do
      Message.called = 0
      conn = GremlinClient::Connection.new
      expect(conn.instance_variable_get('@response')['result']['data']).to eq([1])
      expect(conn.instance_variable_get('@error').data).to eq(
        "{\"requestId\":null,\"status\":{\"code\":null},\"result\":{\"data\":[2],\"meta\":{}}}"
      )
    end
  end


  describe :send do
    it :string do
      conn = GremlinClient::Connection.new
      sock = conn.instance_variable_get('@ws')
      expect(conn).to receive(:wait_connection)
      expect(conn).to receive(:reset_request)
      expect(conn).to receive(:build_message).with(:query, :bindings).and_return(:my_message)
      expect(sock).to receive(:send).with(:my_message, { type: 'text' })
      expect(conn).to receive(:wait_response)
      expect(conn).to receive(:treat_response)

      conn.send_query(:query, :bindings)
    end

    it :file do
      conn = GremlinClient::Connection.new
      expect(IO).to receive(:read).with('filename').and_return(:file_contents)
      expect(conn).to receive(:send_query).with(:file_contents, :bindings)
      conn.send_file('filename', :bindings)
    end
  end


  it :open? do
    conn = GremlinClient::Connection.new
    expect(conn.instance_variable_get('@ws')).to receive(:open?).and_return(:from_websocket)
    expect(conn.open?).to eq(:from_websocket)
  end

  it :close do
    conn = GremlinClient::Connection.new
    expect(conn.instance_variable_get('@ws')).to receive(:close).and_return(:from_websocket)
    expect(conn.close).to eq(:from_websocket)
  end

  describe :receive_message do
    it :no_request_id do
      Message.called = 0
      Message.request_id = nil
      conn = GremlinClient::Connection.new
      conn.send(:reset_request)
      conn.receive_message(Message)
      expect(conn.instance_variable_get('@response')).to be_nil
    end

    it :different_request_id do
      Message.called = 0
      Message.request_id = '123'
      conn = GremlinClient::Connection.new
      conn.send(:reset_request)
      conn.instance_variable_set('@request_id', '123')
      conn.receive_message(Message)
      expect(conn.instance_variable_get('@response')).to eq({
        'requestId' => '123',
        'status' => { 'code' => nil },
        'result' => { 'data' => [2], 'meta' => {} }
      })
      # exit this block reseting this value
      Message.request_id = nil
    end
  end

  it :receive_error do
    conn = GremlinClient::Connection.new
    conn.receive_error(:this_is_a_bad_error)
    expect(conn.instance_variable_get('@error')).to eq(:this_is_a_bad_error)
  end

  describe :wait_connection do
    it :timeouts do
      conn = GremlinClient::Connection.new
      expect(conn).to receive(:open?).and_return(false).at_least(:once)
      expect{conn.send(:wait_connection)}.to raise_exception(::GremlinClient::ConnectionTimeoutError)
    end

    it :success do
      conn = GremlinClient::Connection.new
      expect(conn).to receive(:open?).and_return(true).twice
      conn.send(:wait_connection)
    end

    it :fails_with_longer_timeout do
      conn = GremlinClient::Connection.new(connection_timeout: 3, autoconnect: false)
      conn.connect
      started_at = Time.now.to_i
      expect(conn).to receive(:open?).and_return(false).at_least(:once)
      expect{conn.send(:wait_connection)}.to raise_exception(::GremlinClient::ConnectionTimeoutError)
      expect(Time.now.to_i - started_at).to be_within(1).of(3)
    end

    it :fails_with_autonnect do
      conn = GremlinClient::Connection.new(connection_timeout: 2, autoconnect: true)
      started_at = Time.now.to_i
      expect(conn).to receive(:open?).and_return(false).at_least(:once)
      expect{conn.send(:wait_connection)}.to raise_exception(::GremlinClient::ConnectionTimeoutError)
      expect(Time.now.to_i - started_at).to be_within(1).of(4)
    end
  end


  it :reset_request do
    conn = GremlinClient::Connection.new
    conn.instance_variable_set('@request_id', :old_id)
    conn.instance_variable_set('@started_at', :old_started_at)
    conn.instance_variable_set('@error', :old_error)
    conn.instance_variable_set('@response', :old_response)

    conn.send(:reset_request)

    expect(conn.instance_variable_get('@request_id')).not_to eq(:old_id)
    expect(conn.instance_variable_get('@request_id').length).to be(36) # uuid is 36 chars long
    expect(conn.instance_variable_get('@started_at')).to be_within(1).of(Time.now.to_i)
    expect(conn.instance_variable_get('@error')).to be_nil
    expect(conn.instance_variable_get('@response')).to be_nil
  end


  describe :wait_response do
    it :no_message do
      conn = GremlinClient::Connection.new(timeout: 1)
      conn.send(:reset_request)
      expect{conn.send(:wait_response)}.to raise_exception(::GremlinClient::ExecutionTimeoutError)
    end

    it :wrong_id_message do
      conn = GremlinClient::Connection.new(timeout: 1)
      conn.send(:reset_request)
      Message.request_id = :invalid_id
      conn.receive_message(Message)
      expect{conn.send(:wait_response)}.to raise_exception(::GremlinClient::ExecutionTimeoutError)
    end

    it :with_message do
      conn = GremlinClient::Connection.new(timeout: 1)
      conn.send(:reset_request)
      Message.called = 0
      Message.request_id = conn.instance_variable_get('@request_id')
      conn.receive_message(Message)
      conn.send(:wait_response)
      expect(conn.instance_variable_get('@response')).to eq({
          'requestId' => conn.instance_variable_get('@request_id'),
          'status' => { 'code' => nil } ,
          'result' => { 'data' => [1], 'meta' => {} }
      })
    end

    it :with_error do
      conn = GremlinClient::Connection.new(timeout: 1)
      conn.send(:reset_request)
      Message.called = 0
      Message.request_id = conn.instance_variable_get('@request_id')
      conn.receive_error(Message)
      expect{conn.send(:wait_response)}.to raise_exception(::GremlinClient::ServerError)
    end
  end

  describe :treat_response do
    it :success_statuses do
      def test_status(name)
        conn = GremlinClient::Connection.new
        conn.send(:reset_request)
        Message.request_id = conn.instance_variable_get('@request_id')
        Message.status = name
        conn.receive_message(Message)
        conn.send(:treat_response)
      end
      test_status(:success)
      test_status(:no_content)
      test_status(:partial_content)
    end

    it :error_statuses do
      def test_status(name)
        conn = GremlinClient::Connection.new
        conn.send(:reset_request)
        Message.request_id = conn.instance_variable_get('@request_id')
        Message.status = name
        conn.receive_message(Message)
        expect{conn.send(:treat_response)}.to raise_exception(::GremlinClient::ServerError)
      end

      [
        :unauthorized,
        :authenticate,
        :malformed_request,
        :invalid_request_arguments,
        :server_error,
        :script_evaluation_error,
        :server_timeout,
        :server_serialization_error
      ].each { |name| test_status(name) }
    end
  end

  it :build_message do
    conn = GremlinClient::Connection.new
    conn.send(:reset_request)
    expect(JSON.parse(conn.send(:build_message, :query, :bindings))).to eq({
      'requestId' => conn.instance_variable_get('@request_id'),
      'op' => 'eval',
      'processor' => '',
      'args' => {
        'gremlin' => 'query',
        'bindings' => 'bindings',
        'language' => 'gremlin-groovy'
      }
    })
  end


  it :resolve_path do
    conn = GremlinClient::Connection.new
    expect(conn.send(:resolve_path, 'test')).to eq('test')

    conn = GremlinClient::Connection.new(gremlin_script_path: '/test/path')
    expect(conn.send(:resolve_path, 'test')).to eq('/test/path/test')


    conn = GremlinClient::Connection.new(gremlin_script_path: 'test/path')
    expect(conn.send(:resolve_path, 'test')).to eq('test/path/test')
  end
end
