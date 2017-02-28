# ruby-gremlin
Gremlin client for the WebSocketChannelizer.

This client is not thread safe by itself! If you want to make it safer for your app, please make sure
to use something like [ConnectionPool gem](https://github.com/mperham/connection_pool).


## Usage:

```ruby
conn = GremlinClient.new( host: 'ws://localhost:123')
resp = conn.send("g.V().has('something', 'somevalue')");
```

Alternativelly, you can use erb templates:

```ruby
resp = conn.templateSend("template.groovy.erb", {var1: 12})
```

```groovy
g.V().has("something", <%= params[:var1] %>)
```

