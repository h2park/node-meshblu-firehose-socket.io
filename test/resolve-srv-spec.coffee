{afterEach, beforeEach, describe, it} = global
{expect} = require 'chai'
sinon    = require 'sinon'
SocketIO = require 'socket.io'
Meshblu  = require '../src/firehose-socket-io'

describe 'Meshblu', ->
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
        expect(=> new Meshblu {meshbluConfig}).to.throw(
          'hostname parameter is only valid when the parameter resolveSrv is false'
        )

    describe 'when constructed with resolveSrv true, secure false, and nothing else', ->
      beforeEach ->
        @dns = resolveSrv: sinon.stub()

        meshbluConfig = {resolveSrv: true, secure: false, uuid: '1', token: '1'}
        dependencies = {@dns, @WebSocket}

        @sut = new Meshblu {meshbluConfig}, dependencies

      describe 'when connect is called', ->
        beforeEach 'making the request', (done) ->
          @dns.resolveSrv.withArgs('_meshblu-firehose._socket-io-ws.octoblu.com').yields null, [{
            name: 'localhost'
            port: 34715
            priority: 1
            weight: 100
          }]
          @sut.on 'error', done
          @sut.connect done

        it 'should get here', ->
          # getting here is enough
