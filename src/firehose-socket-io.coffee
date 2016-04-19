_              = require 'lodash'
SocketIOClient = require 'socket.io-client'
EventEmitter2  = require 'eventemitter2'
URL            = require 'url'

class MeshbluFirehoseSocketIO extends EventEmitter2
  @EVENTS = [
    'close'
    'connect'
    'connect_error'
    'connect_timeout'
    'connecting'
    'disconnect'
    'error'
    'reconnect'
    'reconnect_error'
    'reconnect_failed'
    'reconnecting'
    'upgrade'
    'upgradeError'
  ]

  constructor: ({@meshbluConfig, @transports}) ->
    throw new Error('MeshbluFirehoseSocketIO: meshbluConfig.uuid is required') unless @meshbluConfig.uuid?
    throw new Error('MeshbluFirehoseSocketIO: meshbluConfig.token is required') unless @meshbluConfig.token?
    throw new Error('MeshbluFirehoseSocketIO: meshbluConfig.hostname is required') unless @meshbluConfig.hostname?
    throw new Error('MeshbluFirehoseSocketIO: meshbluConfig.port is required') unless @meshbluConfig.port?
    throw new Error('MeshbluFirehoseSocketIO: meshbluConfig.protocol is required') unless @meshbluConfig.protocol?

  connect: ({uuid}, callback) =>
    options =
      path: "/socket.io/v1/#{uuid}"
      extraHeaders:
        'X-Meshblu-UUID': @meshbluConfig.uuid
        'X-Meshblu-Token': @meshbluConfig.token
      query:
        uuid: @meshbluConfig.uuid
        token: @meshbluConfig.token
      transports: @transports

    url = @url {uuid}
    @socket = SocketIOClient url, options
    @socket.once 'connect', =>
      callback()
      callback = ->
    @socket.once 'connect_error', (error) =>
      callback error
      callback = ->
    @bindEvents()

  bindEvents: =>
    @socket.on 'message', @_onMessage
    _.each MeshbluFirehoseSocketIO.EVENTS, (event) =>
      @socket.on event, =>
        @emit event, arguments...

  close: (callback) =>
    @socket.close callback

  url: ({uuid}) =>
    URL.format
      hostname: @meshbluConfig.hostname
      port: @meshbluConfig.port
      protocol: @meshbluConfig.protocol
      slashes: true

  _onMessage: (message) =>
    newMessage =
      metadata: message.metadata

    try
      newMessage.data = JSON.parse message.rawData
    catch
      newMessage.rawData = message.rawData

    @emit 'message', newMessage


module.exports = MeshbluFirehoseSocketIO
