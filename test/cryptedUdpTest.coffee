CryptedUdp = require('../lib/cryptedUdp.coffee')

describe 'CryptedUDP', ->
  seed = new CryptedUdp
    ip: '127.0.0.1'
    port: 41235
  
  peer = new CryptedUdp
    ip: '127.0.0.1'
    port: 41236