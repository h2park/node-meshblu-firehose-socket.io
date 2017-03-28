# node-meshblu-firehose-socket.io
Meshblu Firehose client for socket.io, stream messages from Meshblu Subscriptions.

[![Build Status](https://travis-ci.org/octoblu/node-meshblu-firehose-socket.io.svg?branch=master)](https://travis-ci.org/octoblu/node-meshblu-firehose-socket.io)
[![Code Climate](https://codeclimate.com/github/octoblu/node-meshblu-firehose-socket.io/badges/gpa.svg)](https://codeclimate.com/github/octoblu/node-meshblu-firehose-socket.io)
[![Test Coverage](https://codeclimate.com/github/octoblu/node-meshblu-firehose-socket.io/badges/coverage.svg)](https://codeclimate.com/github/octoblu/node-meshblu-firehose-socket.io)
[![Slack Status](http://community-slack.octoblu.com/badge.svg)](http://community-slack.octoblu.com)

[![NPM](https://nodei.co/npm/meshblu-firehose-socket.io.svg?style=flat)](https://npmjs.org/package/meshblu-firehose-socket.io)

# Table of Contents

* [Getting Started](#getting-started)
  * [Install](#install)
  * [Quick Start](#quick-start)
* [Events](#events)
  * [Event: "message"](#event-message)
* [Methods](#methods)
  * [constructor(options)](#constructoroptions)
  * [firehose.connect()](#firehoseconnect)

# Getting Started

## Install

The Meshblu Firehose socket.io client-side library is best obtained through NPM:

```shell
npm install --save meshblu-firehose-socket.io
```

## Quick Start

The client side library establishes a secure socket.io connection to Meshblu Firehose at `https://meshblu-firehose-socket-io.octoblu.com` by default.

```javascript
var MeshbluFirehoseSocketIO = require('meshblu-firehose-socket.io');
var firehose = new MeshbluFirehoseSocketIO({
  meshbluConfig: {
   hostname: 'meshblu-firehose-socket-io.octoblu.com',
   port: 443,
   protocol: 'wss',
   uuid: '78159106-41ca-4022-95e8-2511695ce64c',
   token: 'd5265dbc4576a88f8654a8fc2c4d46a6d7b85574'
  }
})
firehose.connect();
```

# Events


## Event: "message"

The `message` event is emitted whenever a device sends or receives a message. In order to receive broadcast from a device, your connection must be authenticated as a device that is in the target device's `broadcast.sent` whitelist. To receive message sent by a device, your connection must be in the target's `message.sent` whitelist. To receive messages from other devices, they must be in the authorized device's `message.from` whitelist. See the [Meshblu whitelist documentation](https://meshblu.readme.io/docs/whitelists-2-0) for more information.

* `message` Message object that was received.
  * `metadata` Object containing metadata about the message, including the `route`.
  * `data` The contents of the message.

##### Example

```javascript
firehose.on('message', function(message){
  console.log('on message');
  console.log(JSON.stringify(message, null, 2));
  // on message
  // {
  //   "metadata": {
  //     "responseId": "21af8d3c-002b-4967-b725-71b2369a6ccf",
  //     "route": [
  //       {
  //         "from": "10ab5232-21ff-418b-8153-7b1d80cdc426",
  //         "to": "b0af12c9-4aea-4a48-9cea-53efd759653c",
  //         "type": "broadcast.sent"
  //       },
  //       {
  //         "from": "10ab5232-21ff-418b-8153-7b1d80cdc426",
  //         "to": "b0af12c9-4aea-4a48-9cea-53efd759653c",
  //         "type": "broadcast.received"
  //       },
  //       {
  //         "from": "b0af12c9-4aea-4a48-9cea-53efd759653c",
  //         "to": "b0af12c9-4aea-4a48-9cea-53efd759653c",
  //         "type": "broadcast.received"
  //       }
  //     ]
  //   },
  //   "data": {
  //     "devices": [
  //       "*"
  //     ],
  //     "data": "2016-07-09T04:57:22.998Z"
  //   }
  // }
});

otherConn.message({devices: ['*'], data: new Date()});
```

# Methods

## constructor(options)

Establishes a socket.io connection to Meshblu Firehose and returns the connection object.

##### Arguments

* `options` connection options with the following keys:
  * `protocol` The protocol to use when connecting to the server. Must be one of ws/wss (Default `wss`)
  * `hostname` The hostname of the Meshblu server to connect to. (Default: `meshblu-firehose-socket-io.octoblu.com`)
  * `port` The port of the Meshblu server to connect to. (Default: `443`)
  * `uuid` UUID of the device to connect with.
  * `token` Token of the device to connect with.

##### Example

```javascript
var MeshbluFirehoseSocketIO = require('meshblu-firehose-socket.io');
var conn = new MeshbluFirehoseSocketIO({
  hostname: 'meshblu-firehose-socket-io.octoblu.com',
  port: 443,
  protocol: 'wss',
  uuid: '78159106-41ca-4022-95e8-2511695ce64c',
  token: 'd5265dbc4576a88f8654a8fc2c4d46a6d7b85574'
})
```

#firehoseconnect
## meshblu.connect()

Establish a socket.io connection to Meshblu Firehosea.

##### Note

Connect no longer takes a callback. `message` events will be emitted as soon as messages are received from Meshblu.
On `disconnect` events the firehose will attempt to automatically reconnect.

##### Example


```javascript
firehose.on('connecting', function() {
  console.log('connecting...');
})
firehose.on('connect', function() {
  console.log('connected!');
})
firehose.on('connect_error', function(error) {
  console.error('connect_error', error)
})
firehose.on('disconnect', function() {
  console.log('disconnected!');
})
firehose.on('reconnecting', function() {
  console.log('reconnecting...');
})

firehose.connect()
```
