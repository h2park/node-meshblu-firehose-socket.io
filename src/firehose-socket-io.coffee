SocketIOClient = require 'socket.io-client'
EventEmitter2  = require 'eventemitter2'
URL            = require 'url'

class MeshbluFirehoseSocketIO extends EventEmitter2
  constructor: ({@meshbluConfig}) ->
    throw new Error('MeshbluFirehoseSocketIO: meshbluConfig.uuid is required') unless @meshbluConfig.uuid?
    throw new Error('MeshbluFirehoseSocketIO: meshbluConfig.token is required') unless @meshbluConfig.token?
    throw new Error('MeshbluFirehoseSocketIO: meshbluConfig.hostname is required') unless @meshbluConfig.hostname?
    throw new Error('MeshbluFirehoseSocketIO: meshbluConfig.port is required') unless @meshbluConfig.port?
    throw new Error('MeshbluFirehoseSocketIO: meshbluConfig.protocol is required') unless @meshbluConfig.protocol?

  connect: ({uuid}) =>
    options =
      path: "/socket.io/v1/#{uuid}"
      extraHeaders:
        'X-Meshblu-UUID': @meshbluConfig.uuid
        'X-Meshblu-Token': @meshbluConfig.token

    url = @url {uuid}
    @socket = SocketIOClient url, options
    @socket.on 'connect', =>
      @emit 'connect'

    @socket.on 'disconnect', =>
      @emit 'disconnect'

    @socket.on 'message', (message) =>
      @emit 'message', message

  close: (callback) =>
    @socket.close callback

  url: ({uuid}) =>
    URL.format
      hostname: @meshbluConfig.hostname
      port: @meshbluConfig.port
      protocol: @meshbluConfig.protocol
      slashes: true

module.exports = MeshbluFirehoseSocketIO
