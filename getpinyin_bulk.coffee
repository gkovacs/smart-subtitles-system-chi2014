root = exports ? this
print = console.log

getpinyin = require './getpinyin.coffee'
fs = require 'fs'
subtitleread = require './static/subtitleread.coffee'

redis = require 'redis'
client = redis.createClient()

subtext = fs.readFileSync('static/shaolin.srt', 'utf8')
subtitleGetter = new subtitleread.SubtitleRead(subtext)
keys = ('pinyin|' + x[2] for x in subtitleGetter.timesAndSubtitles)

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
    getpinyin.getPinyin(text, (npy) -> print npy )
    ++i
  , 2500)

main = ->
  client.mget(keys, processRedisReplies)

main() if require.main is module
