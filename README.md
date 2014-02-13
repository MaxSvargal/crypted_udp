CryptedUDP
===========

JSON-RPC with AES-256-CBC crypted UDP sockets over IPv4 for NodeJs


```coffeescript
  node = new CryptedUdp
    address: '127.0.0.1'
    port: 41235
    id: 'da39a3ee5e6b4b0d3255bfef95601890afd80709' # optional sha1 unique client self id
  
  node.on 'message', (msg) ->
    console.log msg

  node.connect '127.0.0.1', 41236, ->
    @send { foo: "bar" }, (msg) ->
      JSON.stringify msg

  # Also  
  peer = node.connect '127.0.0.1', 41236
  peer.send { foo: "bar" }, (msg) ->
    JSON.stringify msg
    
```

### Tests
You need [mocha](http://visionmedia.github.io/mocha/) installed
```sh
npm test
```

### Compile to JavaScript
```sh
npm run-script compile
```