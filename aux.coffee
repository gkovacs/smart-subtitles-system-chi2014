root = exports ? this
print = console.log

fs = require 'fs'
subtitleread = require('./static/subtitleread.coffee')
chinesedict = require('./static/chinesedict.coffee')

subtext = fs.readFileSync('static/shaolin.srt', 'utf8')
subtitleGetter = new subtitleread.SubtitleRead(subtext)

dictText = fs.readFileSync('static/cedict_1_0_ts_utf-8_mdbg.txt', 'utf8')
cdict = new chinesedict.ChineseDict(dictText)

redis = require 'redis'
client = redis.createClient()

getPrevDialogStartTime = (time, callback) ->
  origSub = subtitleGetter.subtitleAtTime(time)
  --time
  while time > 0
    prevsub = subtitleGetter.subtitleAtTime(time-1)
    cursub = subtitleGetter.subtitleAtTime(time)
    if cursub? and cursub != '' and cursub != origSub and prevsub != cursub
      break
    --time
  if time < 0
    time = 0
  callback(time)

getNextDialogStartTime = (time, callback) ->
  origSub = subtitleGetter.subtitleAtTime(time)
  ++time
  while true
    nextsub = subtitleGetter.subtitleAtTime(time+1)
    cursub = subtitleGetter.subtitleAtTime(time)
    if cursub? and cursub != '' and cursub != origSub and nextsub != cursub
      break
    ++time
  if time < 0
    time = 0
  callback(time)

getAnnotatedSubAtTime = (time, callback) ->
  sub = subtitleGetter.subtitleAtTime(time)
  if not sub? or sub == ''
    callback([])
    return
  client.get('pinyin|' + sub, (err, pinyin) ->
    pinyin = pinyin.toLowerCase()
    pinyinWords = []
    curPinyinWord = []
    words = []
    idx = 0
    curWord = []
    for char in sub
      if char.trim() == ''
        continue
      for [cpinyin,english] in cdict.wordLookup[char]
        if cpinyin == pinyin[idx...idx+cpinyin.length]
          curWord.push(char)
          curPinyinWord.push(cpinyin)
          idx += cpinyin.length
          if idx >= pinyin.length or pinyin[idx] == ' ' # end of word
            words.push(curWord.join(''))
            pinyinWords.push(curPinyinWord.join(' '))
            curWord = []
            curPinyinWord = []
            ++idx
          break
    translations = []
    for word,i in words
      translations.push(cdict.getEnglishForWordAndPinyin(word, pinyinWords[i]))
    output = []
    for word,i in words
      output.push([word, pinyinWords[i], translations[i]])
    callback(output)
  )

root.getAnnotatedSubAtTime = getAnnotatedSubAtTime
root.getPrevDialogStartTime = getPrevDialogStartTime
root.getNextDialogStartTime = getNextDialogStartTime

main = ->
  getAnnotatedSubAtTime(900, print)
  getPrevDialogStartTime(900, print)
  getNextDialogStartTime(900, print)
  #process.exit()

main() if require.main is module
