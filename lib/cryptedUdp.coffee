'use strict'

dgram = require 'dgram'
crypto = require 'crypto'

module.exports = class CryptedUdp
  constructor: (@params) ->
    @_awaitingReply = {}
    @_peers = {}
    @_id = @generateId()
    @key = @createKeys()
    @socket = @createSocket @params.address, @params.port
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

  cryptMessage: (msg) ->
    cipher = crypto.createCipher 'aes-256-cbc', @_password
    encrypted = cipher.update msg, 'utf8', 'binary'
    encrypted + cipher.final('binary')

  decryptMessage: (msg) ->
    msg = msg.toString()
    decipher = crypto.createDecipher 'aes-256-cbc', @_password
    decrypted = decipher.update msg, 'binary', 'utf8'
    (decrypted + decipher.final('utf8')).toString()

  sendMessage: (address, port, msg, callback) =>
    message = new Buffer JSON.stringify(msg)
    @socket.send message, 0, message.length, port, address, (err, bytes) ->
      if callback
        callback err if err
        callback bytes

  onMessageHandler: (msg, info) =>
    msg = JSON.parse msg
    @_awaitingReply = {msg: msg, info: info}
    switch msg.method
      when 'CONNECT' then @onConnectHandler msg, info
      when 'CONNECT_REPLY' then @onConnectReplyHandler msg, info

  onConnectHandler: (msg, info) ->
    @sendMessage info.address, info.port,
      'method': 'CONNECT_REPLY'
      'replyTo': @_id
      'publicKey': @key.public

    @_peers["#{info.address}:#{info.port}"] = 
      timestamp: Date.now()
      connected: true
      publicKey: msg.publicKey

  onConnectReplyHandler: (msg, info) ->
    peer = @_peers["#{info.address}:#{info.port}"]
    peer.connected = true
    peer.timestamp = Date.now()
    peer.callback() if peer.callback

  on: (type, callback) ->
    @socket.on 'message', (msg, rinfo) =>
      callback msg, rinfo

  connect: (address, port, callback = new Function) ->
    methods =
      send: (msg, callback) => @sendMessage address, port, msg, callback
      on: @on

    @sendMessage address, port,
      'method': 'CONNECT'
      'replyTo': @_id
      'publicKey': @key.public

    @_peers["#{address}:#{port}"] = { connected: false, callback: callback.bind methods }
    methods

