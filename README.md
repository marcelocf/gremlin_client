# ruby-gremlin
Gremlin client for the WebSocketChannelizer.

This client is not thread safe by itself! If you want to make it safer for your app, please make sure
to use something like [ConnectionPool gem](https://github.com/mperham/connection_pool).


## Usage:

```ruby
conn = GremlinClient.Connection.new( host: 'ws://localhost:123')
resp = conn.send("g.V().has('myVar', myValue)", {myValue: 'this_is_processed_by_gremlin_server'})
```

Alternativelly, you can use groovy files instead:

```ruby
resp = conn.file_send("template.groovy", {var1: 12})
```

```groovy
g.V().has("something", var1)
```

You can even specify the folder where to load those files in the constructor:

```ruby
conn = GremlinClient.Connection.new(groovy_script_path:  'scripts/groovy')
```
