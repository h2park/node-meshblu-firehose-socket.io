MeshbluHttp     = require 'meshblu-http'
MeshbluFirehose = require 'meshblu-firehose-socket.io'
chalk           = require 'chalk'

meshbluHttp = new MeshbluHttp
  hostname: 'meshblu-http.octoblu.com'
  port: 443
  protocol: 'https'

registerReceiver =
  name: 'firehose-test:receiver'

meshbluHttp.register registerReceiver, (error, receiver) =>
  throw error if error?

  console.log "Registered Receiver Device: #{chalk.blue receiver.uuid}"

  receiverMeshbluHttp = new MeshbluHttp
    hostname: 'meshblu-http.octoblu.com'
    port: 443
    protocol: 'https'
    uuid: receiver.uuid
    token: receiver.token

  # be sure to put the receiver in the broadcast.received whitelist
  registerSender =
    name: 'firehose-test:sender'
    meshblu:
      version: '2.0.0'
      whitelists:
        broadcast:
          sent: [
            uuid: receiver.uuid
          ]

  meshbluHttp.register registerSender, (error, sender) =>
    throw error if error?

    console.log "Registered Sender Device: #{chalk.green sender.uuid}"

    # subscribe to all broadcasts received by receiver
    # this is a mandatory step, you will not receive
    # any messages without this subscription
    broadcastReceivedSubscription =
      emitterUuid: receiver.uuid
      subscriberUuid: receiver.uuid
      type: 'broadcast.received'

    receiverMeshbluHttp.createSubscription broadcastReceivedSubscription, (error) =>
      throw error if error?

      console.log "Subscribed to #{chalk.blue receiver.uuid} #{chalk.yellow 'broadcast.received'}"

      # subscribe to all broadcasts sent from sender
      broadcastSentSubscription =
        emitterUuid: sender.uuid
        subscriberUuid: receiver.uuid
        type: 'broadcast.sent'

      receiverMeshbluHttp.createSubscription broadcastSentSubscription, (error) =>
        throw error if error?

        console.log "Subscribed to #{chalk.green sender.uuid} #{chalk.yellow 'broadcast.sent'}"

        meshbluFirehose = new MeshbluFirehose
          meshbluConfig:
            hostname: 'meshblu-firehose-socket-io.octoblu.com'
            port: 443
            protocol: 'wss'
            uuid: receiver.uuid
            token: receiver.token

        meshbluFirehose.on 'message', (message) =>
          # the first route is always the originator of the message
          senderUuid = message.metadata.route[0].from
          console.log chalk.bgCyan '######################################################################'
          console.log "[#{chalk.yellow new Date}]"
          console.log "Received Message from #{chalk.green senderUuid}"
          console.log JSON.stringify message, null, 2
          console.log chalk.bgCyan '######################################################################'

        meshbluFirehose.connect uuid: receiver.uuid, (error) =>
          throw error if error?

          console.log "\n\n"
          console.log chalk.bgMagenta "Waiting for messages..."
          console.log "\n\n"

          senderMeshbluHttp = new MeshbluHttp
            hostname: 'meshblu-http.octoblu.com'
            port: 443
            protocol: 'https'
            uuid: sender.uuid
            token: sender.token

          setInterval =>
            console.log "\nSending broadcast from #{chalk.green sender.uuid}.\n"
            message =
              devices: ['*']
              data: new Date
            senderMeshbluHttp.message message
          , 5000
