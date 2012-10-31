root = exports ? this
print = console.log

#sys = require 'util'
#child_process = require 'child_process'
#fs = require 'fs'

http_get = require 'http-get'

redis = require 'redis'
client = redis.createClient()

escapeUnicodeEncoded = (text) ->
  return unescape(text.split('\\u').join('%u'))

getRomaji = (text, callback) ->
  reqtxt = text.split('"').join('')
  #command = 'w3m "http://translate.google.com/translate_a/t?client=t&text=' + reqtxt + '&sl=zh&tl=zh-CN&ie=UTF-8" -dump'
  #child_process.exec(command, (error, stdout, stderr) ->
  req_headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 6.2; WOW64; rv:16.0.1) Gecko/20121011 Firefox/16.0.1'}
  http_get.get({url: 'http://translate.google.com/translate_a/t?client=t&text=' + reqtxt + '&sl=ja&tl=ja-JP&ie=UTF-8', headers: req_headers}, (err, dlData) ->
    buffer = dlData.buffer
    romaji = buffer.split('","')[3]
    romaji = romaji.split('"]')[0]
    romaji = escapeUnicodeEncoded(romaji)
    client.set('romaji|' + text, romaji)
    callback(text, romaji)
  )

lastRomajiFetchTimestamp = 0

getRomajiRateLimited = (text, callback) ->
  timestamp = Math.round((new Date()).getTime() / 1000)
  if lastRomajiFetchTimestamp + 1 >= timestamp
    setTimeout(() ->
      getRomajiRateLimited(text, callback)
    , 1000)
  else
    lastRomajiFetchTimestamp = timestamp
    getRomaji(text, callback)

getRomajiRateLimitedCached = (text, callback) ->
  client.get('romaji|' + text, (err, reply) ->
    if reply?
      callback(text, reply)
    else
      getRomajiRateLimited(text, callback)
  )

root.getRomajiRateLimitedCached = getRomajiRateLimitedCached

main = ->
  text = process.argv[2]
  print text
  getRomajiRateLimitedCached(text, (ntext, romaji) ->
    print romaji
  )

main() if require.main is module
