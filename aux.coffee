root = exports ? this
print = console.log

fs = require 'fs'
http_get = require 'http-get'

root.portnum = 3000

coffee = require 'iced-coffee-script'

deferred = require 'deferred'

subtitleread = require './static/subtitleread'
subpread = require './static/subpread'
chinesedict = require './static/chinesedict'
japanesedict = require './static/japanesedict'
englishdict = require './static/englishdict'

#dictText = fs.readFileSync('static/cedict_full.txt', 'utf8')
#cdict = new chinesedict.ChineseDict(dictText)
jdictText = fs.readFileSync('static/edict2_full.txt', 'utf8')
jdict = new japanesedict.JapaneseDict(jdictText)
edictText = fs.readFileSync('static/engdict-opted.html', 'utf8')
edict = new englishdict.EnglishDict(edictText)

redis = require 'redis'
client = redis.createClient()

getpinyin = require './getpinyin'
pinyinutils = require './static/pinyinutils'

getprononciation = require './getprononciation'

translator = require './translator'

getchinese_gloss = require './getchinese_gloss'

language = 'zh'
targetLanguage = 'en' # zh-CHS

root.initializeUser = (nuser) ->

  subtitleGetter = null
  nativeSubtitleGetter = {
    subtitleAtTimeAsync: (deciSec, callback) ->
      idx = subtitleGetter.getSubtitleIndexFromTime(deciSec)
      subtext = subtitleGetter.timesAndSubtitles[idx][2]
      getTranslations(subtext, (translation) ->
        callback(translation[0].TranslatedText)
      )
  }
  subPixGetter = null
  
  dlog = (text) ->
    serverlog(text)
    nuser.now.clientlog(text)

  initializeSubtitle = (subtitleSource, nlanguage, tlanguage, doneCallback) ->
    if (not subtitleSource?) or subtitleSource == ''
      return
    downloadSubtitleText(subtitleSource, (subtext) ->
      initializeSubtitleText(subtext, nlanguage, tlanguage, doneCallback)
    )

  initializeNativeSubtitle = (subtitleSource, doneCallback) ->
    if (not subtitleSource?) or subtitleSource == ''
      return
    downloadSubtitleText(subtitleSource, (subtext) ->
      initializeNativeSubtitleText(subtext, doneCallback)
    )

  initializeSubtitleText = (subtitleText, nlanguage, tlanguage, doneCallback) ->
    language = nlanguage
    targetLanguage = tlanguage
    subtitleGetter = new subtitleread.SubtitleRead(subtitleText)
    if doneCallback?
      doneCallback()
    #if nlanguage == "zh"
    #  textlist = (x[2] for x in subtitleGetter.timesAndSubtitles)
    #  for text in textlist
    #    getpinyin.getPinyinRateLimitedCached(text, (ntext, pinyin) ->
    #    )

  initializeNativeSubtitleText = (subtitleText, doneCallback) ->
    nativeSubtitleGetterReal = new subtitleread.SubtitleRead(subtitleText)
    nativeSubtitleGetter = {
    subtitleAtTimeAsync: (deciSec, callback) ->
      idx = subtitleGetter.getSubtitleIndexFromTime(deciSec)
      [start,end,subtext] = subtitleGetter.timesAndSubtitles[idx]
      idx = nativeSubtitleGetterReal.getSubtitleIndexFromTime((start+end)/2)
      ###
      subtextWords = getchinese_gloss.getEnglishWordsInGloss(subtext, (glossWords) ->
        translations = []
        if nativeSubtitleGetterReal.timesAndSubtitles[idx-1]?
          curtrans = nativeSubtitleGetterReal.timesAndSubtitles[idx-1][2]
          if getchinese_gloss.sentenceOverlapPercentageWithWords(curtrans, glossWords) > 0.1
            translations.push curtrans
        translations.push nativeSubtitleGetterReal.timesAndSubtitles[idx][2]
        if nativeSubtitleGetterReal.timesAndSubtitles[idx+1]?
          curtrans = nativeSubtitleGetterReal.timesAndSubtitles[idx+1][2]
          if getchinese_gloss.sentenceOverlapPercentageWithWords(curtrans, glossWords) > 0.1
            translations.push curtrans
        callback translations.join(' | ')
      )
      ###
      isOverHalfOfNativeOrTargetCovered = (start_target, end_target, start_native, end_native) ->
        target_duration = end - start
        native_duration = end_native - start_native
        covered_duration = Math.min(end_native, end_target) - Math.max(start_target, start_native)
        return covered_duration*2 > Math.min(native_duration, target_duration)
      while idx >= 0
        [nstart,nend,nsubtext] = nativeSubtitleGetterReal.timesAndSubtitles[idx]
        if not isOverHalfOfNativeOrTargetCovered(start, end, nstart, nend)
          break
        idx -= 1
      if idx != 0
        idx += 1
      translations = []
      while idx < nativeSubtitleGetterReal.timesAndSubtitles.length
        [nstart,nend,nsubtext] = nativeSubtitleGetterReal.timesAndSubtitles[idx]
        if translations.length > 0 and not isOverHalfOfNativeOrTargetCovered(start, end, nstart, nend)
          break
        translations.push(nsubtext)
        idx += 1
      callback(translations.join(' '))
    }
    if doneCallback?
      doneCallback()

  initializeSubPix = (subPixSource) ->
    if (not subPixSource?) or subPixSource == ''
      return
    downloadSubtitleText(subPixSource, (subPixText) ->
      subPixDir = ''
      if subPixSource.lastIndexOf('/') != -1
        subPixDir = subPixSource[..subPixSource.lastIndexOf('/')]
      subPixGetter = new subpread.SubpRead(subPixText, subPixDir)
    )

  downloadSubtitleText = (subtitleSource, callback) ->
    if subtitleSource.indexOf('http://') == -1
      subtitleSource = 'http://localhost:' + root.portnum + '/' + subtitleSource
    http_get.get({url: subtitleSource}, (err, dlData) ->
      data = dlData.buffer
      callback(data)
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
    ft = ["'", 'zěnmeliǎo']
    dt = ['', 'zěnmele']
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

  groupWordsLongPreservingPinyin = (wordsWithPinyinAndTrans) ->
    longestStartWord = (remainingList) ->
      pinyinForRemaining = pinyinutils.removeToneMarks(cdict.getPinyinForWord((x[0] for x in remainingList).join('')).split(' ').join('').toLowerCase())
      origPinyinForRemaining = pinyinutils.removeToneMarks((x[1] for x in remainingList).join('').split(' ').join('').toLowerCase())
      if pinyinForRemaining == origPinyinForRemaining
        return remainingList
      if remainingList.length == 1
        return remainingList
      return longestStartWord(remainingList[0...remainingList.length-1])
    wordsOrig = wordsWithPinyinAndTrans
    words = []
    i = 0
    while i < wordsOrig.length
      nextWord = (x[0] for x in longestStartWord(wordsOrig[i..]))
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
    return output

  getSubPixAtTime = (time, callback) ->
    if subPixGetter?
      callback(subPixGetter.subtitleAtTime(time))

  getFullAnnotatedSub = (callback) ->
    if language == 'zh'
      getFullAnnotatedSubChinese(callback)
    if language == 'ja'
      getFullAnnotatedSubJapanese(callback)
    else
      getFullAnnotatedSubEnglish(callback)

  getNativeSubAtTime = (time, callback) ->
    idx = subtitleGetter.getSubtitleIndexFromTime(time)
    [startTime,endTime,subLine] = subtitleGetter.timesAndSubtitles[idx]
    midTime = Math.floor((startTime + endTime) / 2)
    nativeSubtitleGetter.subtitleAtTimeAsync(midTime, callback)

  getAnnotatedSubAtTime = (time, callback) ->
    if language == 'zh'
      getAnnotatedSubAtTimeChinese(time, callback)
    if language == 'ja'
      getAnnotatedSubAtTimeJapanese(time, callback)
    if language == 'en'
      getAnnotatedSubAtTimeEnglish(time, callback)

  getAnnotatedSubAtTimeEnglish = (time, callback) ->
    sub = subtitleGetter.subtitleAtTime(time)
    if not sub? or sub == ''
      callback([])
    english_translations = []
    word_list = edict.getWordList(sub)
    await
      for word,idx in word_list
        translator.getTranslations(word, 'en', 'zh-CHS', defer(english_translations[idx]))
    output = []
    for word,idx in word_list
      output.push([word, '', english_translations[idx][0].TranslatedText])
    callback(output)

  getAnnotatedSubAtTimeJapanese = (time, callback) ->
    sub = subtitleGetter.subtitleAtTime(time)
    if not sub? or sub == ''
      callback([])
    jdict.getGlossForSentence(sub, callback)

  getGlossChinese = getchinese_gloss.getWordsPinyinEnglishCached
  ###
  getGlossChinese = (sub, callback) ->
    processPinyin = (pinyin) ->
      #print pinyin
      #print sub
      havePinyin = pinyin.length > 0
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
      
      endWord = ->
        tword = curWord.join('')
        tpinyin = curPinyinWord.join(' ')
        ttranslation = cdict.getEnglishForWordAndPinyin(tword, tpinyin)
        output.push([tword, tpinyin, ttranslation])
        curWord = []
        curPinyinWord = []
      
      for char in sub
        if char.trim() == ''
          continue
        if char == pinyin[idx..idx] or (char == '，' and pinyin[idx..idx] == ',') # punctuation
          endWord()
          #print 'punctuation:' + char + '|' + sub + '|' + time
          output.push([char, '', ''])
          ++idx
          continue
        if not cdict.wordLookup[char]?
          endWord()
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
              endWord()
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
          #print 'could not match:' + char + '|' + sub + '|' + time
          tpinyin = cdict.getPinyinForWord(char)
          ttranslation = cdict.getEnglishForWord(char)
          output.push([char, tpinyin, ttranslation])
          curSeekRange = misSeekRange
          continue
        else
          curSeekRange = defSeekRange
      output = fixSegmentation(output)
      if not havePinyin
        output = groupWordsLong(output)
      else
        output = groupWordsLongPreservingPinyin(output)
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
  ###

  getAnnotatedSubAtTimeChinese = (time, callback) ->
    sub = subtitleGetter.subtitleAtTime(time)
    if not sub? or sub == ''
      callback([])
      return
    getGlossChinese(sub, callback)

  getFullAnnotatedSubChinese = (callback) ->
    allSubLines = subtitleGetter.getTimesAndSubtitles()
    chineseGlossPromise = deferred.promisify(getGlossChinese)
    await
      deferred.map(allSubLines, deferred.gate((e, i) ->
        chineseGlossPromise(e[2])
      , 100))(defer(annotatedSubLines))
    timesAndAnnotatedSubLines = []
    for i in [0...allSubLines.length]
      timesAndAnnotatedSubLines[i] = [allSubLines[i][0], allSubLines[i][1], annotatedSubLines[i]]
    callback(timesAndAnnotatedSubLines)
    #await
    #  for i in [0...allSubLines.length]
    #    getGlossChinese(allSubLines[i][2], defer(annotatedSubLines[i]))
    #timesAndAnnotatedSubLines = []
    #for i in [0...allSubLines.length]
    #  timesAndAnnotatedSubLines[i] = [allSubLines[i][0], allSubLines[i][1], annotatedSubLines[i]]
    #callback(timesAndAnnotatedSubLines)


  getFullAnnotatedSubJapanese = (callback) ->
    allSubLines = subtitleGetter.getTimesAndSubtitles()
    annotatedSubLines = []
    await
      for i in [0...allSubLines.length]
        jdict.getGlossForSentence(allSubLines[i][2], defer(annotatedSubLines[i]))
    timesAndAnnotatedSubLines = []
    for i in [0...allSubLines.length]
      timesAndAnnotatedSubLines[i] = [allSubLines[i][0], allSubLines[i][1], annotatedSubLines[i]]
    callback(timesAndAnnotatedSubLines)

  getFullAnnotatedSubEnglish = (callback) ->
    allSubLines = subtitleGetter.getTimesAndSubtitles()
    annotatedSubLines = []
    for i in [0...allSubLines.length]
      annotatedSubLines[i] = []
      english_translations = []
      word_list = edict.getWordList(allSubLines[i][2])
      await
        for word,idx in word_list
          translator.getTranslations(word, language, targetLanguage, defer(english_translations[idx]))
          #translator.getTranslations(word, 'en', 'zh-CHS', defer(english_translations[idx]))
      for word,idx in word_list
        annotatedSubLines[i].push([word, '', english_translations[idx][0].TranslatedText])
      #for word in edict.getWordList(allSubLines[i][2])
      #  annotatedSubLines[i].push([word, '', edict.getDefnForWord(word)])
    timesAndAnnotatedSubLines = []
    for i in [0...allSubLines.length]
      timesAndAnnotatedSubLines[i] = [allSubLines[i][0], allSubLines[i][1], annotatedSubLines[i]]
    callback(timesAndAnnotatedSubLines)

  getTranslations = (text, callback) ->
    translator.getTranslations(text, language, targetLanguage, callback)

  nuser.now.getNativeSubAtTime = getNativeSubAtTime
  nuser.now.getAnnotatedSubAtTime = getAnnotatedSubAtTime
  nuser.now.getFullAnnotatedSub = getFullAnnotatedSub
  nuser.now.getSubPixAtTime = getSubPixAtTime
  nuser.now.getPrevDialogStartTime = getPrevDialogStartTime
  nuser.now.getNextDialogStartTime = getNextDialogStartTime
  nuser.now.initializeSubtitle = initializeSubtitle
  nuser.now.initializeSubtitleText = initializeSubtitleText
  nuser.now.initializeNativeSubtitle = initializeNativeSubtitle
  nuser.now.initializeNativeSubtitleText = initializeNativeSubtitleText
  nuser.now.initializeSubPix = initializeSubPix
  nuser.now.downloadSubtitleText = downloadSubtitleText
  nuser.now.getPrononciation = getprononciation.getPrononciationRateLimitedCached
  nuser.now.getTranslations = getTranslations
  nuser.now.serverlog = serverlog = (msg) ->
    console.log (new Date().getTime()/1000).toString() + ' | ' + msg

  nuser.now.ceval = (text) ->
    compiled = coffee.compile(text, {bare: true})
    dlog(compiled)
    eval(compiled)

  nuser.now.eval = (text) ->
    eval(text)

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
  #print groupWordsLong([['中华', '', ''], ['人民', 'rm', ''], ['共和国', 'ghg', ''], ['中央', 'zy', ''], ['人民','',''],['政','',''],['府','',''],['门','',''],['户','',''],['网站','','']])
  #print groupWordsLongPreservingPinyin([['中华', 'zhōng huá', ''], ['人民', 'rén mín', ''], ['共和国', 'gòng hé guó', ''], ['中央', 'zy', ''], ['人民','rén mín',''],['政','zhèng',''],['府','fǔ',''],['门','',''],['户','',''],['网站','','']])
  
  
  # crouchingtigerhiddendragon
  #initializeSubtitle('crouchingtigerhiddendragon.srt', 'zh', ->
  #  getAnnotatedSubAtTime(1200, print)
  #)

main() if require.main is module
