root = exports ? this
print = console.log

sys = require 'util'
fs = require 'fs'
http_get = require 'http-get'

redis = require 'redis'
client = redis.createClient()

getPrononciation = (text, callback) ->
  http_get.get({url: 'http://dictionary.reference.com/browse/' + text}, (err, dlData) ->
    buffer = dlData.buffer
    prononc = buffer[buffer.indexOf('<span class="show_spellpr"')..]
    pronstart = '<span class="prondelim">[</span>'
    pronend = '<span class="prondelim">]</span>'
    prononc = prononc[prononc.indexOf(pronstart)+pronstart.length...prononc.indexOf(pronend)]
    prurlstart = '<span class="speaker" audio="'
    prurl = buffer[buffer.indexOf(prurlstart)+prurlstart.length..]
    prurl = prurl[...prurl.indexOf('"')]
    client.set('engprn|' + text, prononc + '|' + prurl)
    callback(text, prononc, prurl)
  )

lastPrononciationFetchTimestamp = 0

getPrononciationRateLimited = (text, callback) ->
  timestamp = Math.round((new Date()).getTime() / 1000)
  if lastPrononciationFetchTimestamp + 1 >= timestamp
    setTimeout(() ->
      getPrononciationRateLimited(text, callback)
    , 1000)
  else
    lastPrononciationFetchTimestamp = timestamp
    getPrononciation(text, callback)

getPrononciationRateLimitedCached = (text, callback) ->
  client.get('engprn|' + text, (err, reply) ->
    if reply?
      prononc = reply[...reply.lastIndexOf('|')]
      prurl = reply[reply.lastIndexOf('|')+1..]
      callback(text, prononc, prurl)
    else
      getPrononciationRateLimited(text, callback)
  )

#root.getPrononciation = getPrononciation
root.getPrononciationRateLimitedCached = getPrononciationRateLimitedCached

main = ->
  text = process.argv[2]
  print text
  getPrononciationRateLimitedCached(text, (ntext, prononc, purl) ->
    print prononc
    print purl
  )

main() if require.main is module
