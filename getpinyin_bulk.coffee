root = exports ? this
print = console.log

getpinyin = require './getpinyin'
fs = require 'fs'
subtitleread = require './static/subtitleread'

redis = require 'redis'
client = redis.createClient()

###
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
    getpinyin.getPinyin(text, (npy) ->
      print text
      print npy
    )
    ++i
  , 2500)
###

main = ->
  #client.mget(keys, processRedisReplies)
  subtext = fs.readFileSync(process.argv[2], 'utf8')
  subtitleGetter = new subtitleread.SubtitleRead(subtext)
  textlist = (x[2] for x in subtitleGetter.timesAndSubtitles)

  for text in textlist
    getpinyin.getPinyinRateLimitedCached(text, (ntext, pinyin) ->
      print ntext
      print pinyin
    )

main() if require.main is module
