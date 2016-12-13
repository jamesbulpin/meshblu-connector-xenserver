{EventEmitter}  = require 'events'
debug           = require('debug')('meshblu-connector-xenserver:index')
xenapi          = require 'xen-api'
series          = require 'run-series'

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

  _findObject: (xapi, xapiclass, name, uuid, callback) =>
    if 1
      if uuid
        api = xapiclass + '.get_by_uuid'
        param = uuid
      else
        api = xapiclass + '.get_by_name_label'
        param = name
      debug ("Calling " + api + "(" + param + ")")
      xapi.call(api, param).then(((callback, param, result) =>
        debug ("API returned " + result)
        if result
          if typeof(result) == 'string'
            # VM.get_by_uuid returns a single string
            callback null, [result]
            return
          else
            # VM.get_by_name_label returns a list of strings - use the first one   
            if result.length > 0
              callback null, result
              return
        callback "Cannot find VM " + param, null
        return
      ).bind(null, callback, param)
      ).catch(((callback, param, error) =>
        message = "Error looking up VM " + param
        callback message, null
        return
      ).bind(null, callback, param)
      )
  
  # Look up a list of objects by name or UUID (argument is a list of objects where
  # each object has a "class" and either "uuid" or "name" member) to return a list
  # of lists of OpaqueRefs
  findObjects: (items) =>
    @getXapi().then((xapi) =>
      actions = []
      items.forEach ((fn, x) ->
        xapiclass = x.class
        name = null
        uuid = null
        name = x.name if x?.name?
        uuid = x.uuid if x?.uuid?
        actions.push(fn.bind(null, xapi, xapiclass, name, uuid))
      ).bind(null, @_findObject)
      return new Promise((resolve, reject) =>
        series actions, (err, result) ->
          if err
            reject err
          else
            resolve result
      )
    ).catch((error) =>
      debug "XenServer connection not available"
      return null
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
