{afterEach, beforeEach, describe, it} = global
{expect} = require 'chai'
sinon    = require 'sinon'
SocketIO = require 'socket.io'
Firehose  = require '../src/firehose-socket-io'

describe 'Firehose', ->
  beforeEach ->
    @server = new SocketIO 34715

  afterEach ->
    @server.close()

  describe 'SRV resolve', ->
    describe 'when constructed with resolveSrv true, and a hostname', ->
      it 'should throw an error', ->
        meshbluConfig = {
          resolveSrv: true
          hostname: 'foo.co'
          uuid: 'foo'
          token: 'toalsk'
        }
        expect(=> new Firehose {meshbluConfig}).to.throw(
          'hostname parameter is only valid when the parameter resolveSrv is false'
        )

    describe 'when constructed with resolveSrv true, secure false, and nothing else', ->
      beforeEach 'create sut', ->
        meshbluConfig = {resolveSrv: true, secure: false, uuid: '1', token: '1'}
        @srvFailover = {}
        @sut = new Firehose { meshbluConfig, @srvFailover }

      describe 'when connect is called', ->
        beforeEach 'making the request', (done) ->
          @srvFailover.resolveUrl = sinon.stub().withArgs('_meshblu-firehose._socket-io-ws.octoblu.com').yields null, 'ws://localhost:34715'
          @sut.on 'error', done
          @sut.once 'connect', done
          @sut.connect()

        it 'should get here', ->
          # getting here is enough
