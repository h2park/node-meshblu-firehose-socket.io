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
        {@pathname, @query} = URL.parse @socket.client.request.url, true
        @uuid = @socket.client.request.headers['x-meshblu-uuid']
        @token = @socket.client.request.headers['x-meshblu-token']
      @sut.connect uuid: 'a-uuid', done

    it 'should connect', ->
      expect(@socket).to.exist
      expect(@pathname).to.equal '/socket.io/v1/a-uuid/'

    it 'should pass along the auth info', ->
      expect(@uuid).to.equal 'a-uuid'
      expect(@token).to.equal 'a-token'
      expect(@query.uuid).to.equal 'a-uuid'
      expect(@query.token).to.equal 'a-token'

  describe '-> onMessage', ->
    beforeEach (done) ->
      @server.on 'connection', (@socket) =>
      @sut.connect uuid: 'a-uuid', done

    beforeEach (done) ->
      message =
        metadata:
          some: "thing"
        rawData: '{"payload":"HI"}'
      @socket.emit 'message', message
      @sut.on 'message', (@message) => done()

    it 'should send me a message', ->
      expect(@message.metadata).to.deep.equal some: 'thing'
      expect(@message.data).to.deep.equal payload: 'HI'

  describe '-> onTypeFrom', ->
    beforeEach (done) ->
      @server.on 'connection', (@socket) =>
      @sut.connect uuid: 'a-uuid', done

    beforeEach (done) ->
      message =
        metadata:
          route: [from:'some-uuid',type:'boo.bear']
          some: "thing"
        rawData: '{"payload":"HI"}'
      @socket.emit 'message', message
      @sut.on 'boo.bear.some-uuid', (@message) => done()

    it 'should send me a message', ->
      expect(@message.data).to.deep.equal payload: 'HI'

  describe '-> onType*', ->
    beforeEach (done) ->
      @server.on 'connection', (@socket) =>
      @sut.connect uuid: 'a-uuid', done

    beforeEach (done) ->
      message =
        metadata:
          route: [from:'some-uuid',type:'green.face']
          some: "thing"
        rawData: '{"payload":"HI"}'
      @socket.emit 'message', message
      @sut.on 'green.face.*', (@message) => done()

    it 'should send me a message', ->
      expect(@message.data).to.deep.equal payload: 'HI'

  describe '-> onSubType**', ->
    beforeEach (done) ->
      @server.on 'connection', (@socket) =>
      @sut.connect uuid: 'a-uuid', done

    beforeEach (done) ->
      message =
        metadata:
          route: [from:'some-uuid',type:'orange.burro']
          some: "thing"
        rawData: '{"payload":"HI"}'
      @socket.emit 'message', message
      @sut.on 'orange.**', (@message) => done()

    it 'should send me a message', ->
      expect(@message.data).to.deep.equal payload: 'HI'
