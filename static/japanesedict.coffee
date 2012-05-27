root = exports ? this
print = console.log

http_get = require 'http-get'
redis = require 'redis'
client = redis.createClient()

parseGloss = (htmlPage) ->
  output = []
  for line in htmlPage.split('\n')
    skipLine = true
    if line[...8] == '<ul><li>'
      line = line[8..].trim()
      skipLine = false
    else if line[...4] == '<li>'
      line = line[4..].trim()
      skipLine = false
    if skipLine
      continue
    if line[-5..] == '</li>'
      line = line[...-5].trim()
    kanji = ''
    furigana = ''
    english = ''
    if line.indexOf('【') == -1 # hiragana-only word
      kanji = line[...line.indexOf(' ')].trim()
      furigana = ''
      english = line[line.indexOf(' ')+1..].trim()
    else
      kanji = line[...line.indexOf('【')].trim()
      line = line[line.indexOf('【')+1..]
      furigana = line[...line.indexOf('】')].trim()
      english = line[line.indexOf('】')+1..].trim()
    #if english.lastIndexOf(';') != -1
    #  english = english[...english.lastIndexOf(';')].trim()
    if english.lastIndexOf('; (P)') != -1
      english = english[...english.lastIndexOf('; (P)')].trim()
    if english.indexOf('<font color="red" size="-1">[Partial Match!]</font>') != -1
      english = english[...english.indexOf('<font color="red" size="-1">[Partial Match!]</font>')].trim()
      output.push([kanji,furigana,english,'partial'])
      continue
    inflectedMessage = 'Possible inflected verb or adjective:'
    if kanji.indexOf(inflectedMessage) == 0 and kanji.indexOf('<br>') != -1
      conjugationForm = kanji[kanji.indexOf(inflectedMessage)+inflectedMessage.length...kanji.indexOf('<br>')]
      kanji = kanji[kanji.indexOf('<br>')+4..].trim()
      english = english + conjugationForm
      output.push([kanji,furigana,english,'inflected'])
      continue
    output.push([kanji,furigana,english])
  return output

class JapaneseDict

  constructor: (dictText) ->
    wordLookup = {} # word => [furigana, definition]
    for line in dictText.split('\n')
      line = line.trim()
      kanjiL = ''
      furiganaL = ''
      english = ''
      if line.indexOf('[') != -1
        kanjiL = line[...line.indexOf('[')].trim()
        furiganaL = line[line.indexOf('[')+1...line.indexOf(']')].trim()
        english = line[line.indexOf('/')+1...-1].trim()
      else
        kanjiL = line[...line.indexOf('/')].trim()
        furiganaL = line[...line.indexOf('/')].trim()
        english = line[line.indexOf('/')+1...-1].trim()
      #havePopular
      popularFurigana = []
      standardFurigana = []
      popularEnglish = []
      standardEnglish = []
      for kanji in kanjiL.split(';')
        if kanji.indexOf('(P)') != -1
          kanji = kanji[...kanji.indexOf('(P)')]
        for furigana in furiganaL.split(';')
          isPopular = furigana.indexOf('(P)') != -1
          if furigana.indexOf('(') != -1
            furigana = furigana[...furigana.indexOf('(')]
          if isPopular
            furigana = furigana[...furigana.indexOf('(P)')]
            popularFurigana.push(furigana)
          else
            standardFurigana.push(furigana)
        if not wordLookup[kanji]?
          wordLookup[kanji] = []
        for furigana in popularFurigana[..].reverse()
          wordLookup[kanji].unshift([furigana, english])
        for furigana in standardFurigana
          wordLookup[kanji].push([furigana, english])
    @wordLookup = wordLookup
    @lastLookupMs = 0
    @mirrors = ['http://www.edrdg.org/cgi-bin/wwwjdic/wwwjdic?9ZIG', 'http://ryouko.imsb.nrc.ca/cgi-bin/wwwjdic/wwwjdic?9ZIG']
    @mirrorIdx = 0

  removeMultiFurigana: (glossList) =>
    output = []
    for [kanji,furigana,english] in glossList
      if furigana? and (furigana.indexOf(';') != -1 or furigana.indexOf('(') != -1)
        if this.wordLookup[kanji]? and this.wordLookup[kanji][0]? # have multiple readings
          furigana = this.wordLookup[kanji][0][0]
        else
          if furigana.indexOf(';') != -1
            furigana = furigana[...furigana.indexOf(';')]
          if furigana.indexOf('(') != -1
            furigana = furigana[...furigana.indexOf('(')]
      output.push([kanji,furigana,english])
    return output

  getWordsForSetence: (sentence, callback) =>
    sentence = sentence.split('　').join('-').split(' ').join('-')
    client.get('jpgloss|' + sentence, (err, res) =>
      if res? and res != '' and res.indexOf('WWWJDIC is undergoing file maintenance.') == -1
        print res
        callback(parseGloss(res))
      else
        curTimeMs = (new Date()).getTime()
        lastLookupMs = this.lastLookupMs
        this.lastLookupMs = curTimeMs
        glossURL = ''
        if curTimeMs - lastLookupMs < 1000 # last request was within a second
          @mirrorIdx = (@mirrorIdx + 1) % @mirrors.length
          glossURL = @mirrors[@mirrorIdx] + sentence
        else
          @mirrorIdx = 0
          glossURL = @mirrors[@mirrorIdx] + sentence
        print 'fetching: ' + glossURL
        http_get.get({url: glossURL}, (err, dlData) ->
          glossData = dlData.buffer
          if glossData.indexOf('WWWJDIC is undergoing file maintenance.') == -1
            callback(parseGloss(glossData))
            client.set('jpgloss|' + sentence, glossData)
          else
            setTimeout( ->
              getWordsForSetence(sentence, callback)
            , 1000)
        )
    )

  getGlossForSentence: (sentence, callback) =>
    this.getWordsForSetence(sentence, (words) =>
      output = []
      print words
      i = 0
      widx = 0
      while widx < words.length
        word = words[widx]
        curWordL = word[0]
        possibleMatches = []
        for x in curWordL.split('\t').join(' ').split(' ')
          possibleMatches.push(x)
        partial = false
        inflected = false
        if word.length == 4 and word[3] == 'partial'
          partial = true
        if word.length == 4 and word[3] == 'inflected'
          inflected = true
        if i >= sentence.length
          break
        curChar = sentence[i]
        haveMatch = false
        for curWord in possibleMatches
          if sentence[i...i+curWord.length] == curWord
            output.push([curWord, word[1], word[2]])
            i += curWord.length
            ++widx
            haveMatch = true
            break
          else if partial and sentence[i...i+2] == curWord[0...2]
            j = 2
            while j <= curWord.length
              if sentence[i...i+j] != curWord[0...j]
                break
              ++j
            matchedStringLength = j-1
            matchedString = sentence[i...i+matchedStringLength]
            output.push([matchedString, word[1], word[2]])
            i += matchedStringLength
            ++widx
            haveMatch = true
            break
          else if inflected and sentence[i...i+1] == curWord[0...1]
            j = 1
            while j <= curWord.length
              if sentence[i...i+j] != curWord[0...j]
                break
              ++j
            matchedStringLength = j-1
            matchedString = sentence[i...i+matchedStringLength]
            furigana = word[1]
            if furigana.indexOf('(') != -1
              furigana = furigana[...furigana.indexOf('(')]
            if furigana.indexOf(';') != -1
              furigana = furigana[...furigana.indexOf(';')]
            # TODO try all furigana and take best one (highest numOkuriGana)
            curWordInv = curWord.split('').reverse().join('')
            furiganaInv = furigana.split('').reverse().join('')
            numOkuriGana = 0
            while numOkuriGana < Math.min(curWord.length, furigana.length)
              if curWordInv[numOkuriGana] != furiganaInv[numOkuriGana]
                break
              ++numOkuriGana
            print "matchedString: #{matchedString}, #{numOkuriGana}, #{curWord}, #{furigana}"
            if numOkuriGana > 0
              furigana = furigana[...-numOkuriGana]
            output.push([matchedString, furigana, word[2]])
            i += matchedStringLength
            ++widx
            haveMatch = true
            break
        if not haveMatch
          output.push([curChar, '', ''])
          ++i
      while i < sentence.length
        curChar = sentence[i]
        output.push([curChar, '', ''])
        ++i
      callback(this.removeMultiFurigana(output))
    )

root.JapaneseDict = JapaneseDict

