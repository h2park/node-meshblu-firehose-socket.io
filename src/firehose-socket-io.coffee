_              = require 'lodash'
SocketIOClient = require 'socket.io-client'
EventEmitter2  = require 'eventemitter2'
URL            = require 'url'

WRONG_SERVER_ERROR = '"identify" received. Likely connected to meshblu-socket-io instead of the meshblu-firehose-socket-io'

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

  constructor: ({meshbluConfig, @transports}, dependencies={}) ->
    super wildcard: true
    {@dns} = dependencies

    throw new Error('MeshbluFirehoseSocketIO: meshbluConfig is required') unless meshbluConfig?
    throw new Error('MeshbluFirehoseSocketIO: meshbluConfig.uuid is required') unless meshbluConfig.uuid?
    throw new Error('MeshbluFirehoseSocketIO: meshbluConfig.token is required') unless meshbluConfig.token?

    {uuid, token}              = meshbluConfig
    {protocol, hostname, port} = meshbluConfig
    {service, domain, secure}  = meshbluConfig
    {resolveSrv}               = meshbluConfig

    if resolveSrv
      @_assertNoUrl {protocol, hostname, port}
      domain  ?= 'octoblu.com'
      service ?= 'meshblu-firehose'
      secure  ?= true
    else
      @_assertNoSrv {service, domain, secure}
      protocol ?= 'https'
      hostname ?= 'meshblu-firehose-socket-io.octoblu.com'
      port     ?= 443

    @meshbluConfig = {uuid, token, resolveSrv, protocol, hostname, port, service, domain, secure}

  connect: (callback) =>
    @_resolveBaseUrl (error, baseUrl) =>
      return callback error if error?

      options =
        path: "/socket.io/v1/#{@meshbluConfig.uuid}"
        extraHeaders:
          'X-Meshblu-UUID': @meshbluConfig.uuid
          'X-Meshblu-Token': @meshbluConfig.token
        query:
          uuid: @meshbluConfig.uuid
          token: @meshbluConfig.token
        transports: @transports

      @socket = SocketIOClient baseUrl, options
      @socket.once 'identify', => @emit 'error', new Error(WRONG_SERVER_ERROR)
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
    @socket.disconnect()
    callback()

  _assertNoSrv: ({service, domain, secure}) =>
    throw new Error('domain parameter is only valid when the parameter resolveSrv is true')  if domain?
    throw new Error('service parameter is only valid when the parameter resolveSrv is true') if service?
    throw new Error('secure parameter is only valid when the parameter resolveSrv is true')  if secure?

  _assertNoUrl: ({protocol, hostname, port}) =>
    throw new Error('protocol parameter is only valid when the parameter resolveSrv is false') if protocol?
    throw new Error('hostname parameter is only valid when the parameter resolveSrv is false') if hostname?
    throw new Error('port parameter is only valid when the parameter resolveSrv is false')     if port?

  _emitWithRoute: (message) =>
    hop = _.first(message.metadata.route)
    return unless hop?
    {from, type} = hop
    channel = "#{type}.#{from}"
    @emit channel, message

  _getSrvAddress: =>
    {service, domain} = @meshbluConfig
    return "_#{service}._#{@_getSrvProtocol()}.#{domain}"

  _getSrvProtocol: =>
    {secure} = @meshbluConfig
    return 'socket-io-wss' if secure
    return 'socket-io-ws'

  _onMessage: (message) =>
    newMessage =
      metadata: message.metadata

    try
      newMessage.data = JSON.parse message.rawData
    catch
      newMessage.rawData = message.rawData

    @emit 'message', newMessage

    @_emitWithRoute newMessage

  _resolveBaseUrl: (callback) =>
    return callback null, @_resolveNormalUrl() unless @meshbluConfig.resolveSrv

    @dns ?= require 'dns'
    @dns.resolveSrv @_getSrvAddress(), (error, addresses) =>
      return callback error if error?
      return callback new Error('SRV record found, but contained no valid addresses') if _.isEmpty addresses
      return callback null, @_resolveUrlFromAddresses(addresses)

  _resolveNormalUrl: =>
    {protocol, hostname, port} = @meshbluConfig

    protocol ?= 'ws'
    protocol  = 'wss' if port == 443

    URL.format {protocol, hostname, port, slashes: true}

  _resolveUrlFromAddresses: (addresses) =>
    {secure} = @meshbluConfig
    address  = _.minBy addresses, 'priority'

    protocol = if secure then 'wss' else 'ws'

    return URL.format {
      protocol: protocol
      hostname: address.name
      port: address.port
      slashes: true
    }


module.exports = MeshbluFirehoseSocketIO
