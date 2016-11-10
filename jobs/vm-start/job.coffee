http = require 'http'

class VmStart
  constructor: ({@connector}) ->
    throw new Error 'VmStart requires connector' unless @connector?
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
              
      xapi.call('VM.start', vmref[0], false, false)

      message = "Starting VM " + name
      status = "ok"
      data = {message, status}
      
      console.log data

      callback null, {metadata, data}
    )
      
  _userError: (code, message) =>
    error = new Error message
    error.code = code
    return error

module.exports = VmStart
