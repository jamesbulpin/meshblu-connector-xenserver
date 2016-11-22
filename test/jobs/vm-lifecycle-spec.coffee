{job} = require '../../jobs/vm-lifecycle'
Connector = require '../../src'
debug = require('debug')('meshblu-connector-xenserver:test')
simple = require('simple-mock')

class MockConnector extends Connector
  mockXapi: (xapi) =>
    debug "Mocking the xapi object"
    simple.mock(xapi, "connect").returnWith("OK")
    simple.mock(xapi, "call").returnWith(['OpaqueRef:01234567-89ab-cdef-0123-456789abcdef'])
    simple.mock(xapi, "status").returnWith("connected")
          
describe 'VmLifecycle', ->
  context 'when given a valid message', ->
    beforeEach (done) ->
      @connector = new MockConnector
      message =
        data:
          name: 'TestVM'
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
