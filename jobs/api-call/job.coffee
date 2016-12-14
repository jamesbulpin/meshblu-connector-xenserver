http = require 'http'
debug = require('debug')('meshblu-connector-xenserver:ApiCall')

class ApiCall
  constructor: ({@connector}) ->
    throw new Error 'ApiCall requires connector' unless @connector?
    
  do: ({data}, callback) =>
    return callback @_userError(422, 'data.api is required') unless data?.api?
    
    {api} = data
    {params} = data if data?.params?

    metadata =
      code: 200
      status: http.STATUS_CODES[200]

    @connector.getXapi().then((xapi) =>
      if params
        try
          debug "parse " + params
          paramobject = JSON.parse(params)
        catch e
          return callback @_userError(422, 'param parse error: ' + e.toString())
      else
        paramobject = []
      paramobject.unshift(api)
      debug "paramobject " + paramobject
      xapi.call.apply(xapi, paramobject).then((response) =>
        debug "response " + response
        status = "ok"
        data = {response, status}      
        debug "Success " + data
        callback null, {metadata, data}
      
      ).catch((error) =>
        return callback @_userError(500, 'Error using Xen-API: ' + error.toString())
      )
    ).catch((error) =>
      return callback @_userError(500, 'Error connecting to Xen-API: ' + error.toString())
    )
      
  _userError: (code, message) =>
    error = new Error message
    error.code = code
    return error

module.exports = ApiCall
