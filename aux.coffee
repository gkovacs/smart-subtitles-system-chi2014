root = exports ? this
print = console.log

root.portnum = 3000

fs = require 'fs'
http_get = require 'http-get'

require 'coffee-script'

subtitleread = require './static/subtitleread'
chinesedict = require './static/chinesedict'
japanesedict = require './static/japanesedict'

dictText = fs.readFileSync('static/cedict_full.txt', 'utf8')
cdict = new chinesedict.ChineseDict(dictText)
jdictText = fs.readFileSync('static/edict2_full.txt', 'utf8')
jdict = new japanesedict.JapaneseDict(jdictText)

subtext = ''
subtitleGetter = {}

redis = require 'redis'
client = redis.createClient()

getpinyin = require './getpinyin'
pinyinutils = require './static/pinyinutils'

language = 'zh'

initializeSubtitle = (subtitleSource, nlanguage) ->
  language = nlanguage
  if subtitleSource.indexOf('/') == -1
    subtitleSource = 'http://localhost:' + root.portnum + '/' + subtitleSource
  http_get.get({url: subtitleSource}, (err, dlData) ->
    subtext = dlData.buffer
    subtitleGetter = new subtitleread.SubtitleRead(subtext)
  )

getPrevDialogStartTime = (time, callback) ->
  time -= 1
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

lookupDataForWord = (word) ->
  return [word, cdict.getPinyinForWord(word), cdict.getEnglishForWord(word)]

groupWordsFast = (wordsWithPinyinAndTrans) ->
  if wordsWithPinyinAndTrans.length == 0
    return []
  curWordData = wordsWithPinyinAndTrans[0]
  for i in [1...wordsWithPinyinAndTrans.length]
    proposedWordChars = curWordData[0] + wordsWithPinyinAndTrans[i][0]
    proposedWordData = lookupDataForWord(proposedWordChars)
    if proposedWordData[2] != ''
      curWordData = proposedWordData
    else
      output.push(curWordData)
      curWordData = wordsWithPinyinAndTrans[i]
  output.push(curWordData)
  return output

groupWordsLong = (wordsWithPinyinAndTrans) ->
  longestStartWord = (remainingList) ->
    if cdict.getPinyinForWord(remainingList.join('')) != ''
      return remainingList
    if remainingList.length == 1
      return remainingList
    return longestStartWord(remainingList[0...remainingList.length-1])
  wordsOrig = (x[0] for x in wordsWithPinyinAndTrans)
  words = []
  i = 0
  while i < wordsOrig.length
    nextWord = longestStartWord(wordsOrig[i..])
    words.push(nextWord.join(''))
    i += nextWord.length

  # words is a flat list of words; turn it into [word,pinyin,english] list
  output = []
  wordsOrigToData = {}
  for x in wordsWithPinyinAndTrans
    wordsOrigToData[x[0]] = x
  for x in words
    if wordsOrigToData[x]?
      output.push(wordsOrigToData[x])
    else
      output.push(lookupDataForWord(x))
  return output

fixSegmentation = (wordsWithPinyinAndTrans) ->
  output = []
  # ensure everything is in dictionary
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
  return groupWordsLong(output)

getAnnotatedSubAtTime = (time, callback) ->
  if language == 'zh'
    getAnnotatedSubAtTimeChinese(time, callback)
  if language == 'ja'
    getAnnotatedSubAtTimeJapanese(time, callback)

getAnnotatedSubAtTimeJapanese = (time, callback) ->
  sub = subtitleGetter.subtitleAtTime(time)
  if not sub? or sub == ''
    callback([])
  jdict.getGlossForSentence(sub, callback)
  

getAnnotatedSubAtTimeChinese = (time, callback) ->
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
      processPinyin('')
      #getpinyin.getPinyin(sub, (npinyin) ->
      #  processPinyin
      #)
  )

root.getAnnotatedSubAtTime = getAnnotatedSubAtTime
root.getPrevDialogStartTime = getPrevDialogStartTime
root.getNextDialogStartTime = getNextDialogStartTime
root.initializeSubtitle = initializeSubtitle

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
  #getAnnotatedSubAtTime(10930, print)
  
  #print fixSegmentation([['中华人民共和国中央人民政府门户网站', '', '']])
  #print fixSegmentation([['中', '', ''], ['华', '', ''], ['人', '', ''], ['民', '', '']])
  #print fixSegmentation([['中华', '', ''], ['人民', '', ''], ['共和国', '', '']]) # doesn't work; 中华人民 not in dictionary
  #print groupWordsLong([['中华', '', ''], ['人民', '', ''], ['共和国', '', '']])
  #print groupWordsLong([['中', '', ''], ['华', '', '']])
  #print groupWordsLong([['中', '', ''], ['华', '', ''], ['人', '', ''], ['民', '', '']])
  print groupWordsLong([['中华', '', ''], ['人民', 'rm', ''], ['共和国', 'ghg', ''], ['中央', 'zy', ''], ['人民','',''],['政','',''],['府','',''],['门','',''],['户','',''],['网站','','']])

main() if require.main is module
