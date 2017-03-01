
# frozen_string_literal: true

require 'spec_helper'

# Tests on the freetext feature
RSpec.describe :connection do
  class MockedSocket
  end

  module Message
    def self.called=(c)
      @called = c
    end

    def self.data
      @called ||= 0
      @called += 1
      "{\"example\" : \"data #{@called}\"}"
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

      conn.send(:query, :bindings)
    end

    it :file do
      conn = GremlinClient::Connection.new
      expect(IO).to receive(:read).with('filename').and_return(:file_contents)
      expect(conn).to receive(:send).with(:file_contents, :bindings)
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

end
