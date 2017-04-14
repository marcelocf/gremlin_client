#!/usr/bin/env ruby

require 'pp'
require 'gremlin_client'


conn = GremlinClient::Connection.new(gremlin_script_path: 'example/scripts')


def build_message(command, bindings)
  message = {
    requestId: 1231231,
    op: 'eval',
    processor: '',
    args: {
      gremlin: command,
      bindings: bindings,
      language: 'gremlin-groovy'
    }
  }
end


msg =build_message('some big string', { lala: 123, lolo: [1,2,3]})

puts JSON.dump(msg)
puts ''
puts ''
puts ''
puts Oj.dump(msg, mode: :compat)
