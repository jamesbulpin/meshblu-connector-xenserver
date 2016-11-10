{EventEmitter}  = require 'events'
debug           = require('debug')('meshblu-connector-xenserver:index')
xenapi          = require 'xen-api'

class Connector extends EventEmitter
  constructor: ->

  getXapi: ->    
    return @xapi
    
  isOnline: (callback) =>
    callback null, running: true

  close: (callback) =>
    debug 'on close'
    callback()

  onConfig: (device={}) =>
    { @serveraddress } = device.options ? {}
    { @username } = device.options ? {}
    { @password } = device.options ? {}
    debug 'on config', @options

  start: (device, callback) =>
    debug 'started'
    @onConfig device
    if !@xapi
      console.log "Connecting to " + @serveraddress + " as " + @username + "/" + @password
      @xapi = xenapi.createClient(
        url: @serveraddress
        auth:
          user: @username
          password: @password
        readOnly: false)
      @xapi.connect()
    callback()

module.exports = Connector
