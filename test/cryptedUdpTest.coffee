CryptedUdp = require('../lib/cryptedUdp.coffee')

describe 'CryptedUDP', ->
  message = '{ "foo": "bar" }'
  password = '0438572837458374572'

  seed = new CryptedUdp
    address: '127.0.0.1'
    port: 41235
  
  peer = new CryptedUdp
    address: '127.0.0.1'
    port: 41236


  describe 'seed constructor', ->
    it 'has generated public key', ->
      seed.key.public.should.be.a.Buffer

    it 'has generated node id', ->
      seed.should.have.property('_id').with.lengthOf 40


  describe 'peer connection', ->
    it 'should be connected', (done) ->
      peer.connect '127.0.0.1', 41235, ->
        done()

    it 'should be cache peer info', ->
      p = peer._peers["127.0.0.1:41235"]
      p.connected.should.be.true
      p.callback.should.be.a.Function

    it 'connect fn should be return peer methods', ->
      p = peer.connect '127.0.0.1', 41235
      p.send.should.be.a.Function


  describe 'crypt functions', ->
    crypted = seed.cryptMessage message, password
    decrypted = seed.decryptMessage crypted, password
    
    it 'message should be encrypted', ->
      crypted.should.be.a.Buffer

    it 'message should be descrypted', ->
      decrypted.should.eql message


    describe 'send crypted message manually', ->
      it 'peer should recieved message', ->
        seed.on 'message', (msg) ->
          msg.should.eql message

        peer.connect '127.0.0.1', 41235, ->
          @send message, ->
            console.log "Message sended"