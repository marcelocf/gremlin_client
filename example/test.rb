#!/usr/bin/env ruby

require 'pp'
require 'gremlin_client'


conn = GremlinClient::Connection.new(gremlin_script_path: 'example/scripts')
pp conn.send_file('test.groovy', {what: 10})
