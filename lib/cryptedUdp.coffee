'use strict'

dgram = require 'dgram'
crypto = require 'crypto'

module.exports = class CryptedUdp
  constructor: ({address, port}) ->
    @_awaitingReply = {}
    @_peers = {}
    @_id = @generateId()
    @key = @createKeys()
    @socket = @createSocket address, port
    @socket.on 'message', @onMessageHandler

  createSocket: (address, port) ->
    socket = dgram.createSocket 'udp4'
    socket.bind port, address
    socket

  createKeys: ->
    key = crypto.getDiffieHellman 'modp5'
    key.public = key.generateKeys()
    key

  generateId: ->
    hash = crypto.createHash 'sha1'
    hash.digest 'hex'

  cryptMessage: (msg, password) ->
    cipher = crypto.createCipher 'aes-256-cbc', password
    encrypted = cipher.update msg, 'utf8', 'binary'
    encrypted + cipher.final('binary')

  decryptMessage: (msg, password) ->
    msg = msg.toString()
    decipher = crypto.createDecipher 'aes-256-cbc', password
    decrypted = decipher.update msg, 'binary', 'utf8'
    (decrypted + decipher.final('utf8')).toString()

  sendMessage: (address, port, msg, callback) =>
    message = new Buffer JSON.stringify(msg)
    @socket.send message, 0, message.length, port, address, (err, bytes) ->
      if callback
        callback err if err
        callback bytes

  sendCryptedMessage: (address, port, msg, callback) =>
    secretKey = @getPeerSecretKey address, port
    throw new Error "No secret key with peer #{address}:#{port}" if not secretKey
    message = new Buffer @cryptMessage(msg, secretKey)
    @socket.send message, 0, message.length, port, address

    peerId = @_peers["#{address}:#{port}"].replyTo
    @_awaitingReply[peerId] =
      timestamp: Date.now()
      callback: callback   

  onMessageHandler: (msg, info) =>
    try
      message = JSON.parse msg
      switch message.method
        when 'CONNECT' then @onConnectHandler message, info
        when 'CONNECT_REPLY' then @onConnectReplyHandler message, info
    catch
      decrypted = @recieveCryptedMessage msg, info

  recieveCryptedMessage: (msg, rinfo) ->
    secretKey = @getPeerSecretKey rinfo.address, rinfo.port
    return if not secretKey
    @decryptMessage msg, secretKey

  onConnectHandler: (msg, info) ->
    @sendMessage info.address, info.port,
      'method': 'CONNECT_REPLY'
      'replyTo': @_id
      'publicKey': @key.public

    @_peers["#{info.address}:#{info.port}"] = 
      timestamp: Date.now()
      connected: true
      publicKey: msg.publicKey
      replyTo: msg.replyTo
    return

  onConnectReplyHandler: (msg, info) ->
    peer = @_peers["#{info.address}:#{info.port}"]
    peer.connected = true
    peer.timestamp = Date.now()
    peer.publicKey = msg.publicKey
    peer.replyTo = msg.replyTo
    peer.callback() if peer.callback
    return

  getPeerSecretKey: (address, port) ->
    peer = @_peers["#{address}:#{port}"]
    if not peer
      new Error "No known peer #{address}:#{port}"
      return false
    if not peer.publicKey
      new Error "Peer #{address}:#{port} not connected yet"
      return false
    @getSecretExchangeKey peer.publicKey

  getSecretExchangeKey: (other_public_key) ->
    @key.computeSecret new Buffer(other_public_key), null, 'hex'

  on: (type, callback) ->
    @socket.on 'message', (msg, rinfo) =>
      msg = @onMessageHandler msg, rinfo
      if msg then callback msg

  awaitedCallbacks: ->
    if message.replyTo and @_awaitingReply.hasOwnProperty message.replyTo
      cb = @_awaitingReply[message.replyTo].callback
      delete @_awaitingReply[message.replyTo]
      cb message
    return

  connect: (address, port, callback = new Function) ->
    methods =
      send: (msg, callback) => @sendCryptedMessage address, port, msg, callback
      on: @on

    @sendMessage address, port,
      'method': 'CONNECT'
      'replyTo': @_id
      'publicKey': @key.public

    @_peers["#{address}:#{port}"] = { connected: false, callback: callback.bind methods }
    methods

