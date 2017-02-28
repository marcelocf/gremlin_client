#!/usr/bin/env ruby

require 'pp'
require 'gremlin_client'


conn = GremlinClient::Connection.new

pp conn.send('1+what', {what: 10})

pp conn.send('g.V().count()')

conn.close
