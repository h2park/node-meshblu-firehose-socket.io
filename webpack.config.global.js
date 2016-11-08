var path              = require('path');
var webpack           = require('webpack');
module.exports = {
  entry: [
    './src/firehose-socket-io.coffee'
  ],
  output: {
    library: 'MeshbluFirehose',
    path: path.join(__dirname, 'deploy', 'firehose-meshblu-socket.io', 'latest'),
    filename: 'meshblu-firehose.bundle.js'
  },
  module: {
    loaders: [
      {
        test: /\.coffee$/, loader: 'coffee', include: /src/
      }
    ]
  },
  node: {
    dns: 'mock'
  },
  plugins: [
    new webpack.IgnorePlugin(/^(buffertools)$/), // unwanted "deeper" dependency
    new webpack.NoErrorsPlugin(),
    new webpack.optimize.OccurenceOrderPlugin(),
    new webpack.DefinePlugin({
      'process.env': {
        'NODE_ENV': JSON.stringify('production')
      }
    }),
    new webpack.optimize.UglifyJsPlugin({
      compressor: {
        screw_ie8: true,
        warnings: false
      }
    })
   ]
};
