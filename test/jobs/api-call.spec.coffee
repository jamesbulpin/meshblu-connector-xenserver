{job} = require '../../jobs/api-call'
Connector = require '../../src'
debug = require('debug')('meshblu-connector-xenserver:test')
simple = require('simple-mock')

class MockConnector extends Connector
  mockXapi: (xapi) =>
    debug "Mocking the xapi object"
    simple.mock(xapi, "connect").resolveWith("OK")
    simple.mock(xapi, "call").resolveWith(['OpaqueRef:01234567-89ab-cdef-0123-456789abcdef'])
    simple.mock(xapi, "status").returnWith("connected")
          
describe 'ApiCall', ->
  context 'when given a valid message', ->
    beforeEach (done) ->
      @connector = new MockConnector
      message =
        data:
          api: 'VM.get_by_name_label'
          params: '["TestVM"]'
      @sut = new job {@connector}
      @sut.do message, (@error) =>
        debug @error
        done()

    it 'should not error', ->
      expect(@error).not.to.exist

  context 'when given a valid message with no params', ->
    beforeEach (done) ->
      @connector = new MockConnector
      message =
        data:
          api: 'VM.no_param_call'
      @sut = new job {@connector}
      @sut.do message, (@error) =>
        debug @error
        done()

    it 'should not error', ->
      expect(@error).not.to.exist

  context 'when given an invalid message', ->
    beforeEach (done) ->
      @connector = {}
      message = {}
      @sut = new job {@connector}
      @sut.do message, (@error) =>
        done()

    it 'should error', ->
      expect(@error).to.exist

  context 'when given invalid params', ->
    beforeEach (done) ->
      @connector = new MockConnector
      message =
        data:
          api: 'VM.get_by_name_label'
          params: "['TestVM']"
      @sut = new job {@connector}
      @sut.do message, (@error) =>
        done()

    it 'should error', ->
      expect(@error).to.exist
