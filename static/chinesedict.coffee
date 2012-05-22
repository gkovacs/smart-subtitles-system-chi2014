root = exports ? this
print = console.log

pinyinutils = require './pinyinutils.coffee'

class ChineseDict
  constructor: (dictText) ->
    wordLookup = {} # word => [pinyin, definition]
    for line in dictText.split('\n')
      line = line.trim()
      if line[0] == '#'
        continue
      trad = line[0...line.indexOf(' ')]
      line = line[line.indexOf(' ')+1..]
      simp = line[0...line.indexOf(' ')]
      line = line[line.indexOf(' ')+1..]
      pinyin = line[line.indexOf('[')+1...line.indexOf(']')]
      pinyin = pinyinutils.toneNumberToMark(pinyin)
      #print simp
      #print trad
      #print pinyin
      english = line[line.indexOf('/')+1...-1]
      if not wordLookup[trad]?
        wordLookup[trad] = []
      wordLookup[trad].push([pinyin, english])
      if trad != simp
        if not wordLookup[simp]?
          wordLookup[simp] = []
        wordLookup[simp].push([pinyin, english])
    @wordLookup = wordLookup

  getWordList: (sentence) ->
    return sentence.split('') # TODO

  getPinyinForWord: (word) ->
    res = this.wordLookup[word]
    if res? and res.length > 0
      return res[0][0]
    else
      return ''

  getEnglishForWord: (word) ->
    res = this.wordLookup[word]
    if res? and res.length > 0
      return res[0][1]
    else
      return ''

  getEnglishForWordAndPinyin: (word, pinyin) ->
    res = this.wordLookup[word]
    if res? and res.length > 0
      for x in res
        if x[0] == pinyin
          return x[1]
      return res[0][1]
    return ''

  getPinyin: (sentence) ->
    wordList = this.getWordList(sentence)
    print wordList
    nwordList = (this.getPinyinForWord(word) for word in wordList)
    print nwordList
    print nwordList.length
    return nwordList.join(' ')

root.ChineseDict = ChineseDict

