#!/usr/bin/env ruby

require 'pp'
require 'gremlin_client'


conn = GremlinClient::Connection.new(gremlin_script_path: 'example/scripts')

pp conn.send_query('1+what', {what: 10})

pp conn.send_query('0 && 1')

pp conn.send_file('test.groovy', {what: Time.now.to_i})

conn.close
