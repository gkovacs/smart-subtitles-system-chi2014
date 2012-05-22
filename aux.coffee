root = exports ? this
print = console.log

fs = require 'fs'
subtitleread = require('./static/subtitleread.coffee')
chinesedict = require('./static/chinesedict.coffee')

subtext = fs.readFileSync('static/shaolin.srt', 'utf8')
subtitleGetter = new subtitleread.SubtitleRead(subtext)

dictText = fs.readFileSync('static/cedict_1_0_ts_utf-8_mdbg.txt', 'utf8')
cdict = new chinesedict.ChineseDict(dictText)

getAnnotatedSubAtTime = (time, callback) ->
  sub = subtitleGetter.subtitleAtTime(time)
  if not sub? or sub == ''
    return []
  wordsInSub = sub.split('') # TODO fix
  output = []
  for word in wordsInSub
    pinyin = cdict.getPinyinForWord(word)
    english = cdict.getEnglishForWord(word)
    output.push([word, pinyin, english])
  callback(output)

root.getAnnotatedSubAtTime = getAnnotatedSubAtTime

main = ->
  getAnnotatedSubAtTime(100, (x) -> print x)

main() if require.main is module
