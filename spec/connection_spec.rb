
# frozen_string_literal: true

require 'spec_helper'

# Tests on the freetext feature
RSpec.describe :connection do
  class MockedSocket
  end

  module Message
    def self.requestId=(requestId)
      @requestId = requestId
    end

    def self.called=(c)
      @called = c
    end

    def self.data
      @called ||= 0
      @called += 1
      rid = ", \"requestId\" : \"#{@requestId}\"" unless @requestId.nil?
      "{\"example\" : \"data #{@called}\"#{rid}}"
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

    it :groovy_script_path do
      conn = GremlinClient::Connection.new
      expect(conn.groovy_script_path).to eq(Pathname.new('.'))
      conn = GremlinClient::Connection.new(groovy_script_path: '/etc/groovy')
      expect(conn.groovy_script_path).to eq(Pathname.new('/etc/groovy'))
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
      expect(conn.instance_variable_get('@response')).to eq({'example' => 'data 1'})
      expect(conn.instance_variable_get('@error').data).to eq("{\"example\" : \"data 2\"}")
    end
  end


  describe :send do
    it :string do
      conn = GremlinClient::Connection.new
      sock = conn.instance_variable_get('@ws')
      expect(conn).to receive(:wait_connection)
      expect(conn).to receive(:reset_timer)
      expect(conn).to receive(:build_message).with(:query, :bindings).and_return(:my_message)
      expect(sock).to receive(:send).with(:my_message, { type: 'text' })
      expect(conn).to receive(:wait_response)
      expect(conn).to receive(:parse_response)

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
      Message.requestId = nil
      conn = GremlinClient::Connection.new
      conn.send(:reset_timer)
      conn.receive_message(Message)
      expect(conn.instance_variable_get('@response')).to be_nil
    end

    it :different_request_id do
      Message.called = 0
      Message.requestId = '123'
      conn = GremlinClient::Connection.new
      conn.send(:reset_timer)
      conn.instance_variable_set('@requestId', '123')
      conn.receive_message(Message)
      expect(conn.instance_variable_get('@response')).to eq({'example' => 'data 2', 'requestId' => '123'})
      # exit this block reseting this value
      Message.requestId = nil
    end
  end

  it :receive_error do
    conn = GremlinClient::Connection.new
    conn.receive_error(:this_is_a_bad_error)
    expect(conn.instance_variable_get('@error')).to eq(:this_is_a_bad_error)
  end

  it :wait_connectino do
  end
end
