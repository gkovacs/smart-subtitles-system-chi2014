root = exports ? this
print = console.log

fs = require 'fs'

require 'coffee-script'

subtitleread = require './static/subtitleread'
chinesedict = require './static/chinesedict'

subtext = fs.readFileSync('static/shaolin.srt', 'utf8')
subtitleGetter = new subtitleread.SubtitleRead(subtext)

dictText = fs.readFileSync('static/cedict_full.txt', 'utf8')
cdict = new chinesedict.ChineseDict(dictText)

redis = require 'redis'
client = redis.createClient()

getpinyin = require './getpinyin'
pinyinutils = require './static/pinyinutils'

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
  while time < subtitleGetter.lastStartTime
    nextsub = subtitleGetter.subtitleAtTime(time+1)
    cursub = subtitleGetter.subtitleAtTime(time)
    if cursub? and cursub != '' and cursub != origSub and nextsub != cursub
      break
    ++time
  if time >= subtitleGetter.lastStartTime
    callback(time)
    return
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
  ft = ["'"]
  dt = ['']
  return pinyinutils.replaceAllList(pinyin, ft, dt)

fixSegmentation = (wordsWithPinyinAndTrans) ->
  output = []
  for [word,pinyin,english] in wordsWithPinyinAndTrans
    if not english or english == ''
      wordsList = cdict.getWordList(word)
      allPinyin = pinyin.split(' ')
      wordIdx = 0
      for cword in wordsList
        cpinyin = allPinyin[wordIdx...wordIdx+cword.length].join(' ')
        cenglish = cdict.getEnglishForWordAndPinyin(cword, cpinyin)
        output.push([cword, cpinyin, cenglish])
        wordIdx += cword.length
    else
      output.push([word,pinyin,english])
  return output

getAnnotatedSubAtTime = (time, callback) ->
  sub = subtitleGetter.subtitleAtTime(time)
  if not sub? or sub == ''
    callback([])
    return
  processPinyin = (pinyin) ->
    #print pinyin
    #print sub
    pinyin = fixPinyin(pinyin)
    pinyinNoTone = pinyinutils.removeToneMarks(pinyin)
    curPinyinWord = []
    words = []
    idx = 0
    curWord = []
    # how many characters to seek forward for a match in the pinyin
    defSeekRange = 3
    misSeekRange = 10
    curSeekRange = defSeekRange
    output = []
    
    for char in sub
      if char.trim() == ''
        continue
      if not cdict.wordLookup[char]?
        #print 'word lookup failed:' + char + '|' + sub + '|' + time
        output.push([char, '', ''])
        ++curSeekRange
        continue
      haveMatch = false
      for fidx in [0..curSeekRange]
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
            tword = curWord.join('')
            tpinyin = curPinyinWord.join(' ')
            ttranslation = cdict.getEnglishForWordAndPinyin(tword, tpinyin)
            output.push([tword, tpinyin, ttranslation])
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
        tpinyin = cdict.getPinyinForWord(char)
        ttranslation = cdict.getEnglishForWord(char)
        output.push([char, tpinyin, ttranslation])
        curSeekRange = misSeekRange
        continue
      else
        curSeekRange = defSeekRange
    output = fixSegmentation(output)
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
  # shaolin
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
  #getAnnotatedSubAtTime(9183, print)
  #getAnnotatedSubAtTime(27401, print)
  
  # bodyguards
  #getAnnotatedSubAtTime(5723, print)
  #getAnnotatedSubAtTime(5728, print)
  #getAnnotatedSubAtTime(1251, print)
  #getAnnotatedSubAtTime(5725, print)
  getAnnotatedSubAtTime(10930, print)

main() if require.main is module
