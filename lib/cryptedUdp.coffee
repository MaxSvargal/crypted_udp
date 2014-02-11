'use strict'

dgram = require 'dgram'
crypto = require 'crypto'
Bacon = require('baconjs').Bacon

module.exports = class CryptedUdp