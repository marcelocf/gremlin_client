# Ruby Gremlin Client


[![Build Status](https://travis-ci.org/marcelocf/gremlin_client.svg?branch=master)](https://travis-ci.org/marcelocf/gremlin_clien)
[![Gem Version](https://badge.fury.io/rb/gremlin_client.svg)](https://badge.fury.io/rb/gremlin_client)
![](http://ruby-gem-downloads-badge.herokuapp.com/gremlin_client?color=brightgreen)
[![Coverage Status](https://coveralls.io/repos/github/marcelocf/gremlin_client/badge.svg?branch=master)](https://coveralls.io/github/marcelocf/gremlin_client?branch=master)



```
=================================== WARNING ===================================
|| If you are using version 0.1.2 or prior please update! Your results won't ||
|| be consistent while you don't do so!                                      ||
=================================== WARNING ===================================
```
Details on the above at
[#3](https://github.com/marcelocf/gremlin_client/issues/3)


Gremlin client in ruby for the WebSocketChannelizer.

This client is not thread safe by itself! If you want to make it safer for your app, please make sure
to use something like [ConnectionPool gem](https://github.com/mperham/connection_pool).

## Usage:

```bash
gem instal gremlin_client
```

```ruby
conn = GremlinClient::Connection.new(host: 'localhost', port:123)
resp = conn.send_query("g.V().has('myVar', myValue)", {myValue: 'this_is_processed_by_gremlin_server'})
```

Alternativelly, you can use groovy files instead:

```ruby
resp = conn.file_send("query.groovy", {var1: 12})
```

```groovy
g.V().has("something", var1)
```

You can even specify the folder where to load those files in the constructor:

```ruby
conn = GremlinClient::Connection.new(gremlin_script_path:  'scripts/gremlin')
```


## TODO:

The following things are priority in our list of things to do, but we haven't had time to implement
yet:

* rspec
* SSL support
* authentication

The following is very nice to have, but since we are testing against Titan 1.0.0, which has a pretty
old version of Gremlin, we still rely on groovy to do more complex parsing. But as soon as JanusGraph
is release it would be nice to start working on:

* ruby-side syntax like `g.V.hasLabel("omg")..`
* compiled Gremlin query generation
