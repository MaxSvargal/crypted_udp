'use strict'

dgram = require 'dgram'
crypto = require 'crypto'
Bacon = require('baconjs').Bacon

module.exports = class CryptedUdp
  constructor: (@params) ->
    @_awaitingReply = {}
    @_peers = {}
    @_id = @generateId()
    @socket = @createSocket @params.address, @params.port
    @key = @createKeys()
    @socket.on 'message', @onMessage
    
  createSocket: (address, port) ->
    socket = dgram.createSocket 'udp4'
    socket.bind port, @address
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

  sendMessage: (ip, port, msg, callback) ->
    message = new Buffer JSON.stringify(msg)
    @socket.send message, 0, message.length, port, ip, (err, bytes) ->
      callback err if err
      callback bytes

  onMessage: ->
    console.log "MESSAGE HERE!"
    @_awaitingReply = {msg: msg, info: info}
    console.log @_awaitingReply