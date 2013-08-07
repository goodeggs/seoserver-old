#!/usr/bin/env node

var program = require('commander');
var fs = require('fs');
var forever = require('forever-monitor');

// require our seoserver npm package

program
  .version('0.0.1')
  .option('-p, --port <port>', 'The port to bind to')
  .option('-h, --host <hostname>', 'The hostname to proxy to')

program
  .command('start')
  .description('Starts up an SeoServer on default port 3000')
  .action(function () {
    var port = program.port || process.env.PORT || 3000;
    var host = program.host || process.env.HOST || 'localhost:4000';
    var child = new (forever.Monitor)(__dirname + '/../lib/seoserver.js', {
      options: [port, host]
    });
    child.start();
  });

program.parse(process.argv);

