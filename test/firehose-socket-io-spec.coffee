MeshbluFirehoseSocketIO = require '../'
SocketIO                = require 'socket.io'

describe 'MeshbluFirehoseSocketIO', ->
  beforeEach ->
    @server = SocketIO()
    @server.listen 0xd00d

  afterEach ->
    @server.close()

  beforeEach ->
    @sut = new MeshbluFirehoseSocketIO {
      meshbluConfig:
        hostname: 'localhost'
        port: 0xd00d
        protocol: 'http'
        uuid: 'a-uuid'
        token: 'a-token'
    }

  describe '-> url', ->
    it 'should return a url', ->
      expect(@sut.url()).to.equal 'http://localhost:53261'

  describe '-> connect', ->
    beforeEach (done) ->
      @server.on 'connection', (@socket) =>
        @uuid = @socket.client.request.headers['x-meshblu-uuid']
        @token = @socket.client.request.headers['x-meshblu-token']
      @sut.connect()
      @sut.on 'connect', done

    it 'should connect', ->
      expect(@socket).to.exist

    it 'should pass along the auth info', ->
      expect(@uuid).to.equal 'a-uuid'
      expect(@token).to.equal 'a-token'

  describe '-> onMessage', ->
    beforeEach (done) ->
      @server.on 'connection', (@socket) =>
      @sut.connect()
      @sut.on 'connect', done

    beforeEach (done) ->
      @socket.emit 'message', {some: "thing"}
      @sut.on 'message', (@message) => done()

    it 'should send me a message', ->
      expect(@message).to.deep.equal some: 'thing'
