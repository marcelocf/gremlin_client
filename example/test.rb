#!/usr/bin/env ruby

require 'pp'
require 'gremlin_client'


conn = GremlinClient::Connection.new(groovy_script_path: 'example/scripts')

pp conn.send('1+what', {what: 10})

pp conn.send('g.V().count()')

pp conn.send_file('test.groovy', {what: Time.now.to_i})

conn.close
