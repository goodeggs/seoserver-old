page = require('webpage').create();
system = require 'system'

lastReceived = new Date().getTime()
requestCount = 0
responseCount = 0
requestIds = []

page.viewportSize = { width: 1024, height: 768 }

page.onResourceReceived = (response) ->
  requestIdx = requestIds.indexOf(response.id)
  if requestIdx isnt -1
    lastReceived = new Date().getTime()
    responseCount++
    requestIds[requestIdx] = null
    
page.onResourceRequested = (request) ->
  unless request.id in requestIds
    requestIds.push request.id
    requestCount++

page.open system.args[1], (->)

checkComplete = ->
  return unless new Date().getTime() - lastReceived > 300 and requestCount is responseCount
  clearInterval checkCompleteInterval
  console.log page.content
  phantom.exit()
    
checkCompleteInterval = setInterval checkComplete, 1

