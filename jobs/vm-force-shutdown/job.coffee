http = require 'http'
debug = require('debug')('meshblu-connector-xenserver:VmHardShutdown')

class VmHardShutdown
  constructor: ({@connector}) ->
    throw new Error 'VmHardShutdown requires connector' unless @connector?
    
  do: ({data}, callback) =>
    return callback @_userError(422, 'data.name is required') unless data?.name?
    
    {name} = data

    metadata =
      code: 200
      status: http.STATUS_CODES[200]

    @connector.getXapi().then((xapi) =>
      xapi.call('VM.get_by_name_label', name).then((vmref) =>

        if !vmref || vmref.length == 0
          message = "Cannot find VM " + name
          status = "error"
          data = {message, status}
          callback null, {metadata, data}
          return
              
        xapi.call('VM.hard_shutdown', vmref[0]).then((response) =>
      
          message = "Hard Shutdown of VM " + name
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
      )
    ).catch((error) =>
      message = "XenServer connection not available for VM " + name
      status = "error"
      data = {message, status}
      callback null, {metadata, data}
      return
    )
      
  _userError: (code, message) =>
    error = new Error message
    error.code = code
    return error

module.exports = VmHardShutdown
