root = exports ? this
print = console.log

sys = require 'util'
child_process = require 'child_process'
fs = require 'fs'

redis = require 'redis'
client = redis.createClient()

subtitleread = require './static/subtitleread.coffee'

subtext = fs.readFileSync('static/shaolin.srt', 'utf8')
subtitleGetter = new subtitleread.SubtitleRead(subtext)
keys = ('pinyin|' + x[2] for x in subtitleGetter.timesAndSubtitles)

escapeUnicodeEncoded = (text) ->
  return unescape(text.split('\\u').join('%u'))

getPinyin = (text) ->
  command = 'w3m "http://translate.google.com/translate_a/t?client=t&text=' + text + '&sl=zh&tl=zh-TW&ie=UTF-8" -dump'
  print text
  child_process.exec(command, (error, stdout, stderr) ->
    pinyin = stdout.split('","')[2]
    pinyin = escapeUnicodeEncoded(pinyin)
    print pinyin
    client.set('pinyin|' + text, pinyin)
  )

processRedisReplies = (err, replies) ->
  keysToFetch = []
  for reply,i in replies
    if reply?
      continue
    key = keys[i]
    key = key[key.indexOf('|')+1..]
    keysToFetch.push(key)
  i = 0
  setInterval( ->
    if i >= keysToFetch.length
      process.exit()
    text = keysToFetch[i]
    getPinyin(text)
    ++i
  , 2500)


client.mget(keys, processRedisReplies)

