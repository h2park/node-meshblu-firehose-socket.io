MeshbluFirehoseSocketIO = require '../'
URL                     = require 'url'
SocketIO                = require 'socket.io'

describe 'MeshbluFirehoseSocketIO', ->
  beforeEach ->
    @server = new SocketIO 0xd00d

  afterEach ->
    @server.close()

  beforeEach ->
    @sut = new MeshbluFirehoseSocketIO {
      meshbluConfig:
        hostname: 'localhost'
        port: 0xd00d
        protocol: 'ws'
        uuid: 'a-uuid'
        token: 'a-token'
      transports: ['websocket']
    }

  describe '-> url', ->
    it 'should return a url', ->
      expect(@sut.url uuid: 'a-uuid').to.equal 'ws://localhost:53261'

  describe '-> connect', ->
    beforeEach (done) ->
      @server.on 'connection', (@socket) =>
        {@pathname} = URL.parse @socket.client.request.url
        @uuid = @socket.client.request.headers['x-meshblu-uuid']
        @token = @socket.client.request.headers['x-meshblu-token']
      @sut.connect uuid: 'a-uuid'
      @sut.on 'connect', done

    it 'should connect', ->
      expect(@socket).to.exist
      expect(@pathname).to.equal '/socket.io/v1/a-uuid/'

    it 'should pass along the auth info', ->
      expect(@uuid).to.equal 'a-uuid'
      expect(@token).to.equal 'a-token'

  describe '-> onMessage', ->
    beforeEach (done) ->
      @server.on 'connection', (@socket) =>
      @sut.connect uuid: 'a-uuid'
      @sut.on 'connect', done

    beforeEach (done) ->
      @socket.emit 'message', {some: "thing"}
      @sut.on 'message', (@message) => done()

    it 'should send me a message', ->
      expect(@message).to.deep.equal some: 'thing'
