root = exports ? this
print = console.log

fs = require 'fs'
subtitleread = require './static/subtitleread.coffee'
chinesedict = require './static/chinesedict.coffee'

subtext = fs.readFileSync('static/shaolin.srt', 'utf8')
subtitleGetter = new subtitleread.SubtitleRead(subtext)

dictText = fs.readFileSync('static/cedict_1_0_ts_utf-8_mdbg.txt', 'utf8')
cdict = new chinesedict.ChineseDict(dictText)

redis = require 'redis'
client = redis.createClient()

getpinyin = require './getpinyin.coffee'
pinyinutils = require './static/pinyinutils.coffee'

getPrevDialogStartTime = (time, callback) ->
  time -= 10
  while time > 0
    prevsub = subtitleGetter.subtitleAtTime(time-1)
    cursub = subtitleGetter.subtitleAtTime(time)
    if cursub? and cursub != '' and prevsub != cursub
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
  while time > 0
    prevsub = subtitleGetter.subtitleAtTime(time-1)
    cursub = subtitleGetter.subtitleAtTime(time)
    if cursub? and cursub != '' and prevsub != cursub
      break
    --time
  if time < 0
    time = 0
  callback(time)

fixPinyin = (pinyin) ->
  pinyin = pinyin.toLowerCase()
  # substitutions for errors in Google's pinyin service
  ft = ['shéme', "'"]
  dt = ['shénme', '']
  return pinyinutils.replaceAllList(pinyin, ft, dt)

getAnnotatedSubAtTime = (time, callback) ->
  sub = subtitleGetter.subtitleAtTime(time)
  if not sub? or sub == ''
    callback([])
    return
  processPinyin = (pinyin) ->
    pinyin = fixPinyin(pinyin)
    pinyinNoTone = pinyinutils.removeToneMarks(pinyin)
    pinyinWords = []
    curPinyinWord = []
    words = []
    idx = 0
    curWord = []
    for char in sub
      if char.trim() == ''
        continue
      if not cdict.wordLookup[char]?
        print 'word lookup failed:' + char + '|' + sub + '|' + time
        continue
      haveMatch = false
      for fidx in [0,1,2,3]
        if haveMatch
          break
        nidx = idx + fidx
        havePinyinMatch = ->
          idx = nidx
          haveMatch = true
          curWord.push(char)
          curPinyinWord.push(pinyin[idx...idx+cpinyin.length])
          idx += cpinyin.length
          if idx >= pinyin.length or pinyin[idx] == ' ' # end of word
            words.push(curWord.join(''))
            pinyinWords.push(curPinyinWord.join(' '))
            curWord = []
            curPinyinWord = []
        for [cpinyin,english] in cdict.wordLookup[char]
          if haveMatch
            break
          if cpinyin == pinyin[nidx...nidx+cpinyin.length]
            havePinyinMatch()
            break
        for [cpinyin,english] in cdict.wordLookup[char]
          if haveMatch
            break
          cpinyin = pinyinutils.removeToneMarks(cpinyin)
          if cpinyin == pinyin[nidx...nidx+cpinyin.length]
            havePinyinMatch()
        for [cpinyin,english] in cdict.wordLookup[char]
          if haveMatch
            break
          cpinyin = cpinyin.toLowerCase()
          if cpinyin == pinyin[nidx...nidx+cpinyin.length]
            havePinyinMatch()
        for [cpinyin,english] in cdict.wordLookup[char]
          if haveMatch
            break
          cpinyin = pinyinutils.removeToneMarks(cpinyin.toLowerCase())
          if cpinyin == pinyin[nidx...nidx+cpinyin.length]
            havePinyinMatch()
        for [cpinyin,english] in cdict.wordLookup[char]
          if haveMatch
            break
          cpinyin = pinyinutils.removeToneMarks(cpinyin)
          if cpinyin == pinyinNoTone[nidx...nidx+cpinyin.length]
            havePinyinMatch()
        for [cpinyin,english] in cdict.wordLookup[char]
          if haveMatch
            break
          cpinyin = pinyinutils.removeToneMarks(cpinyin.toLowerCase())
          if cpinyin == pinyinNoTone[nidx...nidx+cpinyin.length]
            havePinyinMatch()
      if not haveMatch
        print 'could not match:' + char + '|' + sub + '|' + time
        continue
    translations = []
    for word,i in words
      translations.push(cdict.getEnglishForWordAndPinyin(word, pinyinWords[i]))
    output = []
    for word,i in words
      output.push([word, pinyinWords[i], translations[i]])
    callback(output)

  client.get('pinyin|' + sub, (err, rpinyin) ->
    if rpinyin? and rpinyin != ''
      processPinyin(rpinyin)
    else
      print 'not in redis:' + sub
      #getpinyin.getPinyin(sub, (npinyin) ->
      #  processPinyin
      #)
  )

root.getAnnotatedSubAtTime = getAnnotatedSubAtTime
root.getPrevDialogStartTime = getPrevDialogStartTime
root.getNextDialogStartTime = getNextDialogStartTime

main = ->
  #getAnnotatedSubAtTime(20, print)
  #getAnnotatedSubAtTime(9000, print)
  #getPrevDialogStartTime(9000, print)
  #getNextDialogStartTime(9000, print)
  #process.exit()
  #getAnnotatedSubAtTime(38017, print)
  #getAnnotatedSubAtTime(38345, print)
  #getAnnotatedSubAtTime(7985, print)
  #getAnnotatedSubAtTime(16388, print)
  #getAnnotatedSubAtTime(3820, print)
  getAnnotatedSubAtTime(9183, print)

main() if require.main is module
