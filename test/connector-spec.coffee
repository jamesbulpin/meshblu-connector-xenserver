Connector = require '../'
tmp = require 'tmp'
fs = require 'fs'
NodeRSA = require 'node-rsa'

describe 'Connector', ->
  beforeEach (done) ->
    @sut = new Connector
    @sut.start {}, done

  afterEach (done) ->
    @sut.close done

  describe '->isOnline', ->
    it 'should yield running true', (done) ->
      @sut.isOnline (error, response) =>
        return done error if error?
        expect(response.running).to.be.true
        done()

  describe '->onConfig', ->
    describe 'when called with a config', ->
      it 'should not throw an error', ->
        expect(=> @sut.onConfig { type: 'hello' }).to.not.throw(Error)

  describe '->getCredentials', ->
    describe 'when using plaintext credentials', ->
      beforeEach (done) ->
        @sut.onConfig { options: { username: 'testusername', password: 'testpassword' } }
        done()

      it 'should return the correct credentials', ->
        creds = @sut.getCredentials()
        expect(creds.username).to.be.equal('testusername')
        expect(creds.password).to.be.equal('testpassword')
        
    describe 'when using encrypted credentials', ->
      beforeEach (done) ->
        testkeyprv = '-----BEGIN RSA PRIVATE KEY-----\nMIIBOwIBAAJBAJ52CqDT7AolMqcO32p77cmue3D2NJfZ0+oCTJnVbbd1z+kkuSh3\nMgIZK2Zdy0Pb7rL7LY9x0+dfmW6YLJMhu+0CAwEAAQJAMW+mNTKoaynbuZ68ON5c\n+xTCUiWdltpQcKsy9rNNPXS3NN40wBOOqYFzdXNVlBjMatBbth0cBqRyiXjKiEAa\niQIhAORVRFwEqqPE+P/AQfJboyn+zbrBAL6MIZNo69HqlJmLAiEAsalk/SB9XWtg\nQ819PwI8N7mAbf4V58JB4+Q545kEf2cCIC+rJXRYfQ9npdwu1RW1z+CKk4SzmmYt\ndy0BMIpIgPF1AiEArRzlNa0Z2xSMyaSKfQH9kULk/MiPqbNkpt209qwccNMCIQDN\nePElmnffWYBgqnob4U6kEa7AT+Yhqwm83g6sRWSxLg==\n-----END RSA PRIVATE KEY-----'
        testkeypub = '-----BEGIN PUBLIC KEY-----\nMFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBAJ52CqDT7AolMqcO32p77cmue3D2NJfZ\n0+oCTJnVbbd1z+kkuSh3MgIZK2Zdy0Pb7rL7LY9x0+dfmW6YLJMhu+0CAwEAAQ==\n-----END PUBLIC KEY-----'
        key = new NodeRSA testkeypub
        tmpobj = tmp.fileSync()
        fs.writeFileSync tmpobj.fd, testkeyprv
        fs.closeSync tmpobj.fd
        @sut.onConfig { options: { username: key.encrypt("testusername", 'base64'), password: key.encrypt("testpassword", 'base64'), credskey:tmpobj.name } }
        done()

      it 'should return the correct credentials', ->
        creds = @sut.getCredentials()
        console.log creds
        expect(creds.username).to.be.equal('testusername')
        expect(creds.password).to.be.equal('testpassword')
        
        
  #      
        