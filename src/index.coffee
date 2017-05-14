{EventEmitter}  = require 'events'
debug           = require('debug')('meshblu-connector-xenserver:index')
xenapi          = require 'xen-api'
series          = require 'run-series'
NodeRSA         = require 'node-rsa'
fs              = require 'fs'

class Connector extends EventEmitter
  constructor: ->
    @xapi = null
    @intervals = {}
    
  mockXapi: (xapi) ->

  getCredentials: ->
    if @credskey?
      data = fs.readFileSync @credskey, 'utf8'
      key = new NodeRSA(data)
      return { username: key.decrypt(@username, 'utf8'), password: key.decrypt(@password, 'utf8') }
    else
      return { username: @username, password: @password }

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
          auth: @getCredentials()
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
            # get_by_uuid returns a single string
            callback null, [result]
            return
          else
            # get_by_name_label returns a list of strings   
            if result.length > 0
              callback null, result
              return
        callback "Cannot find " + xapiclass + " " + param, null
        return
      ).bind(null, callback, param)
      ).catch(((callback, param, error) =>
        message = "Error looking up " + xapiclass + " " + param
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
    { @credskey } = device.options ? {}
    debug 'on config', device.options

    # Kill any existing metrics intervals
    for metric, interval of @intervals
      debug 'Killing interval loop for', metric
      clearInterval interval
      delete @intervals[metric]
    
    # Create any new intervals
    if device.options? and device.options.hostmetrics?
      for hm in device.options.hostmetrics
        if hm?.data_source?
          data_source = hm.data_source
          aggregate = hm.aggregate ? "sum"
          interval = hm.interval ? 5000
          debug 'Creating metric streaming of ' + data_source + ' (' + aggregate + ') every ' + interval + 'ms'
          clearInterval @intervals[data_source] if data_source of @intervals
          @intervals[data_source] = setInterval(@intervalHandler.bind(null, data_source, aggregate), interval)
      
  start: (device, callback) =>
    debug 'started'
    @onConfig device
    @getXapi().then((xapi) =>
      debug "Initial connection complete"
    )
    callback()

  _getMetric: (xapi, hostref, data_source, callback) =>
    debug 'About to query data source on host', hostref, data_source
    xapi.call("host.query_data_source", hostref, data_source).then(((callback, result) =>
      debug ("host.query_data_source API returned " + result)
      if result
        return callback null, result
      message = "No data returned fetching metric " + data_source + " from " + hostref
      callback message, null
    ).bind(null, callback)
    ).catch(((callback, error) =>
      message = "Error fetching metric " + data_source + " from " + hostref + ": " + error
      callback message, null
      return
    ).bind(null, callback)
    )
    
  intervalHandler: (data_source, aggregate) =>
    debug 'intervalHandler', data_source, aggregate
      
    # Get the data_source value from each host and aggregate as instructed
    @getXapi().then((xapi) =>
      xapi.call('host.get_all').then((hosts) =>
        actions = []
        for hostref in hosts
          actions.push(@_getMetric.bind(null, xapi, hostref, data_source))
        series actions, ((connector, err, result) ->
          debug 'intervalHandler error', err if err
          if result
            agg = undefined
            debug 'Got values for ' + data_source, result
            switch aggregate
              when 'sum'
                agg = result.reduce ((a, b) ->
                  a + b
                ), 0
              when 'mean'
                agg = result.reduce ((a, b) ->
                  a + b
                ), 0
                agg =  agg/result.length
            if agg != undefined
              connector.emit 'message', { devices: "*", data: {data_source:data_source, aggregate:aggregate, value:agg}}
        ).bind(null, this)
      ).catch((error) =>
        debug "Error looking up hosts for metrics:", error
        return null
      )
    ).catch((error) =>
      debug "XenServer connection not available"
      return null
    ) 

module.exports = Connector
