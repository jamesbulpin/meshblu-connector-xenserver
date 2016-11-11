{EventEmitter}  = require 'events'
debug           = require('debug')('meshblu-connector-xenserver:index')
xenapi          = require 'xen-api'

class Connector extends EventEmitter
  constructor: ->
    @xapi = null
    
  mockXapi: (xapi) ->
    
  getXapi: ->
    return new Promise((resolve, reject) =>
      if @xapi && (@xapi.status == "connected")
        debug "getXapi returning existing connection"
        resolve(@xapi)
      else
        debug "Connecting to " + @serveraddress + " as " + @username + "/" + @password
        if @xapi
          @xapi.disconnect()
        @xapi = xenapi.createClient(
          url: @serveraddress
          auth:
            user: @username
            password: @password
          readOnly: false)
        @mockXapi @xapi
        @xapi.connect().then((result) =>
          debug "Xapi connect success"
          resolve(@xapi)
        ).catch((error) =>
          debug "Xapi connect error: " + error
          reject(Error "unable to connect to XenServer")
        )
    )
    
  isOnline: (callback) =>
    callback null, running: true

  close: (callback) =>
    debug 'on close'
    callback()

  onConfig: (device={}) =>
    { @serveraddress } = device.options ? {}
    { @username } = device.options ? {}
    { @password } = device.options ? {}
    debug 'on config'
 
  start: (device, callback) =>
    debug 'started'
    @onConfig device
    @getXapi().then((xapi) =>
      debug "Initial connection complete"
    )
    callback()
    
module.exports = Connector
