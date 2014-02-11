CryptedUdp = require('../lib/cryptedUdp.coffee')

describe 'CryptedUDP', ->
  message = '{ "foo": "bar" }'

  seed = new CryptedUdp
    ip: '127.0.0.1'
    port: 41235
  
  peer = new CryptedUdp
    ip: '127.0.0.1'
    port: 41236

  describe 'seed', ->
    it 'has generated public key', ->
      seed.key.public.should.be.a.Buffer

    it 'has generated node id', ->
      seed.should.have.property('_id').with.lengthOf(40)

  describe 'crypt functions', ->
    seed._password = '0438572837458374572'
    crypted = seed.cryptMessage message
    decrypted = seed.decryptMessage crypted
    
    it 'should be encrypted', ->
      crypted.should.be.a.Buffer

    it 'should be descrypted', ->
      decrypted.should.eql message

  describe 'sended message', ->
    it 'should be return callback', (done) ->
      seed.sendMessage '127.0.0.1', 41236, message, ->
        done()

    it 'should be received by peer', (done) ->
      check = ->
        peer._awaitingReply.should.eql
          msg: seed.cryptMessage message
          info:
            address: '127.0.0.1'
            family: 'IPv4'
            port: 41235
            size: 22

        done()
      setTimeout check, 100