root = exports ? this
print = console.log

sys = require 'util'
child_process = require 'child_process'
fs = require 'fs'

redis = require 'redis'
client = redis.createClient()

escapeUnicodeEncoded = (text) ->
  return unescape(text.split('\\u').join('%u'))

getPinyin = (text, callback) ->
  reqtxt = text.split('"').join('')
  command = 'w3m "http://translate.google.com/translate_a/t?client=t&text=' + reqtxt + '&sl=zh&tl=zh-TW&ie=UTF-8" -dump'
  child_process.exec(command, (error, stdout, stderr) ->
    pinyin = stdout.split('","')[2]
    pinyin = escapeUnicodeEncoded(pinyin)
    client.set('pinyin|' + text, pinyin)
    callback(text, pinyin)
  )

lastPinyinFetchTimestamp = 0

getPinyinRateLimited = (text, callback) ->
  timestamp = Math.round((new Date()).getTime() / 1000)
  if lastPinyinFetchTimestamp + 1 >= timestamp
    setTimeout(() ->
      getPinyinRateLimited(text, callback)
    , 1000)
  else
    lastPinyinFetchTimestamp = timestamp
    getPinyin(text, callback)

getPinyinRateLimitedCached = (text, callback) ->
  client.get('pinyin|' + text, (err, reply) ->
    if reply?
      callback(text, reply)
    else
      getPinyinRateLimited(text, callback)
  )

#root.getPinyin = getPinyin
root.getPinyinRateLimitedCached = getPinyinRateLimitedCached

main = ->
  text = process.argv[2]
  print text
  getPinyinRateLimitedCached(text, (ntext, pinyin) ->
    print pinyin
  )

main() if require.main is module
