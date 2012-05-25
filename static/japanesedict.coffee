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
    if english.lastIndexOf(';') != -1
      english = english[...english.lastIndexOf(';')].trim()
    if english.lastIndexOf('; (P)') != -1
      english = english[...english.lastIndexOf('; (P)')].trim()
    if english.indexOf('<font color="red" size="-1">[Partial Match!]</font>') != -1
      english = english[...english.indexOf('<font color="red" size="-1">[Partial Match!]</font>')].trim()
      output.push([kanji,furigana,english,'partial'])
      continue
    if kanji.indexOf('Possible inflected verb or adjective:') == 0 and kanji.indexOf('<br>') != -1
      kanji = kanji[kanji.indexOf('<br>')+4..].trim()
      output.push([kanji,furigana,english,'inflected'])
      continue
    output.push([kanji,furigana,english])
  return output

class JapaneseDict

  getWordsForSetence: (sentence, callback) ->
    client.get('jpgloss|' + sentence, (err, res) ->
      if res? and res != ''
        callback(parseGloss(res))
      else
        glossURL = 'http://www.edrdg.org/cgi-bin/wwwjdic/wwwjdic?9ZIG' + sentence
        print 'fetching: ' + glossURL
        http_get.get({url: glossURL}, (err, dlData) ->
          glossData = dlData.buffer
          callback(parseGloss(glossData))
          client.set('jpgloss|' + sentence, glossData)
        )
    )

  getGlossForSentence: (sentence, callback) ->
    this.getWordsForSetence(sentence, (words) ->
      output = []
      i = 0
      widx = 0
      while widx < words.length
        word = words[widx]
        curWord = word[0]
        possibleMatches = []
        for x in curWord.split('\t').join(' ').split(' ')
          possibleMatches.push(x)
        partial = false
        partialMinMatch = 2
        if word.length == 4 and word[3] == 'partial'
          partial = true
        if word.length == 4 and word[3] == 'inflected'
          partial = true
          partialMinMatch = 1
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
          else if partial and sentence[i...i+partialMinMatch] == curWord[0...partialMinMatch]
            j = partialMinMatch
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
        if not haveMatch
          output.push([curChar, '', ''])
          ++i
      callback(output)
    )

root.JapaneseDict = JapaneseDict

