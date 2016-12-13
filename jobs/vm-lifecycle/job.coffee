http = require 'http'
debug = require('debug')('meshblu-connector-xenserver:VmLifecycle')

class VmLifecycle
  constructor: ({@connector}) ->
    throw new Error 'VmLifecycle requires connector' unless @connector?
    
  do: ({data}, callback) =>
    return callback @_userError(422, 'either data.name or data.uuid is required') unless data?.name? || data?.uuid?
    return callback @_userError(422, 'data.operation is required') unless data?.operation?
    
    {operation} = data
    {name} = data if data?.name?
    {uuid} = data if data?.uuid?

    metadata =
      code: 200
      status: http.STATUS_CODES[200]

    @connector.getXapi().then((xapi) =>
      # Look up the VM by name or UUID (based on what the user supplied - if both, favour the more precise UUID)
      lookuplist = []
      lookupvm = {
        class: "VM"
        uuid: uuid
        name: name
      }
      lookuplist.push(lookupvm)
      
      @connector.findObjects(lookuplist).then((results) =>
        vmref = null
        if results
          if results[0]
            if results[0].length > 0
              vmref = results[0][0]
              
        debug("VMref " + vmref)              
        if !vmref
          if uuid
            message = "Cannot find VM " + uuid
          else
            message = "Cannot find VM " + name
          status = "error"
          data = {message, status}
          callback null, {metadata, data}
          return

        switch operation
          when 'start' then callargs = ['VM.start', vmref, false, false]
          when 'shutdown' then callargs = ['VM.shutdown', vmref]
          when 'reboot' then callargs = ['VM.clean_reboot', vmref]
          else return callback @_userError(422, 'Unknown operation ' + operation)
          
        xapi.call.apply(xapi, callargs).then((response) =>
      
          if uuid
            message = "Executed VM " + operation + " on " + uuid
          else
            message = "Executed VM " + operation + " on " + name
          status = "ok"
          data = {message, status}
      
          debug "Success " + data
          callback null, {metadata, data}
      
        ).catch((error) =>
          message = error.toString()
          status = "error"
          data = {message, status}

          debug "Error " + data
          callback null, {metadata, data}
        )
      ).catch((error) =>
        console.log error
        message = error
        status = "error"
        data = {message, status}
        callback null, {metadata, data}
        return
      )
    ).catch((error) =>
      message = "XenServer connection not available"
      status = "error"
      data = {message, status}
      callback null, {metadata, data}
      return
    )
      
  _userError: (code, message) =>
    error = new Error message
    error.code = code
    return error

module.exports = VmLifecycle
