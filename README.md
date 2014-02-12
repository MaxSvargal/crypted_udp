CryptedUDP
===========

JSON-RPC with AES-256-CBC crypted sockets over UPD/IPv6 for NodeJs


```coffeescript
  node = new CryptedUdp
    address: '127.0.0.1'
    port: 41235
  
  node.on 'message', (msg) ->
    console.log msg
  
  peer = node.connect '127.0.0.1', 41236
  peer.send { foo: "bar" }, (msg) ->
    JSON.stringify msg
    
```

### Tests
```sh
npm test
```

### Compile to JavaScript
```sh
npm run-script compile
```
