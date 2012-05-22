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
  command = 'w3m "http://translate.google.com/translate_a/t?client=t&text=' + text + '&sl=zh&tl=zh-TW&ie=UTF-8" -dump'
  child_process.exec(command, (error, stdout, stderr) ->
    pinyin = stdout.split('","')[2]
    pinyin = escapeUnicodeEncoded(pinyin)
    client.set('pinyin|' + text, pinyin)
    callback(pinyin)
  )

root.getPinyin = getPinyin

main = ->
  text = process.argv[2]
  print text
  getPinyin(text, (pinyin) ->    
    print pinyin
  )

main() if require.main is module
