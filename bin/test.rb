#!/usr/bin/env ruby

require 'pp'
require 'gremlin_client'


conn = GremlinClient::Connection.new

pp conn.send('1+2')

conn.close
