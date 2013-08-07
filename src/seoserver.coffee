http = require 'http'
{spawn} = require 'child_process'
express = require 'express'
httpProxy = require 'http-proxy'

running = false
[PORT, HOST] = process.argv.splice(2)
[BE_HOSTNAME, BE_PORT] = HOST.split(':')

# Log uncaught exceptions
process.on 'uncaughtException', (err) ->
  console.error('Uncaught exception in server', err.toString())
  
# WATCH FOR ABORTED REQUESTS
# # code to handle connection abort
# req.connection.on 'close', ->

# ADD A UBER TIMEOUT FOR REQUESTS (30 seconds?)

removeScript = /<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi

getContent = (url, callback) ->
  content = ''
  phantom = spawn 'phantomjs', ['--load-images=true', __dirname + '/phantom-server.js', url]
  phantom.stdout.setEncoding 'utf8'
  phantom.stdout.on 'data', (data) ->
    content += data.toString()
  phantom.stderr.on 'data', (data) ->
    console.log "stderr: #{data}"
  phantom.on 'exit', (code) ->
    if code is 0
      callback null, content.replace(removeScript, '')
    else
      callback new Error("phantom exited with status code #{code}")
      
proxy = new httpProxy.RoutingProxy()

acceptsMatcher = /^text\/html/i

respond = (req, res, next) ->
  if acceptsMatcher.test(req.headers.accept)
    res.header 'Access-Control-Allow-Origin', '*'
    res.header 'Access-Control-Allow-Headers', 'X-Requested-With'
    getContent "#{req.protocol}://#{HOST}#{req.url}", (err, content) ->
      return next(err) if err?
      res.send content
  else
    proxy.proxyRequest(req, res, {https: req.secure, host: BE_HOSTNAME, port: (BE_PORT or (req.secure and 443 or 80))})

app = express()
app.enable 'trust proxy'
app.use express.logger()
app.use respond

server = http.createServer(app)

server.on 'listening', ->
  console.log "SeoServer listening on port #{PORT}, proxying to #{HOST}"
  running = true
  
server.on 'close', ->
  console.log 'SeoServer server closed'

# Allow graceful shutdown
process.on 'SIGTERM', ->
  console.log 'SIGTERM received'
  server.close() if running

server.listen PORT, (err) ->
  throw err if err?

