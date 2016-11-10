http = require 'http'

class VmShutdown
  constructor: ({@connector}) ->
    throw new Error 'VmShutdown requires connector' unless @connector?
    console.log "foo"
    
  do: ({data}, callback) =>
    return callback @_userError(422, 'data.name is required') unless data?.name?
    
    {name} = data

    xapi = @connector.getXapi()
    
    xapi.call('VM.get_by_name_label', name).then((vmref) =>
      metadata =
        code: 200
        status: http.STATUS_CODES[200]

      if !vmref || vmref.length == 0
        message = "Cannot find VM " + name
        status = "error"
        data = {message, status}
        callback null, {metadata, data}
        return
              
      xapi.call('VM.shutdown', vmref[0])

      message = "Shutting down VM " + name
      status = "ok"
      data = {message, status}
      
      console.log data

      callback null, {metadata, data}
    )
      
  _userError: (code, message) =>
    error = new Error message
    error.code = code
    return error

module.exports = VmShutdown
