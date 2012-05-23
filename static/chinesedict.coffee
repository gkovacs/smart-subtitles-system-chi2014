root = exports ? this
print = console.log

pinyinutils = require './pinyinutils'

noDuplicates = (list) ->
  output = []
  for x in list
    if x not in output
      output.push(x)
  return output

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
      readings = [pinyin]
      if english.indexOf('pr. [') != -1
        prn = english[english.indexOf('pr. [')+'pr. ['.length..]
        prn = prn[...prn.indexOf(']')]
        prn = pinyinutils.toneNumberToMark(prn)
        readings.push(prn)
      forms = [trad, simp, trad.replace('甚', '什'), trad.replace('沒', '没')]
      forms = noDuplicates(forms)
      for form in forms
        if not wordLookup[form]?
          wordLookup[form] = []
        for reading in readings
          # prioritize readings that start with lowercases
          if reading.toLowerCase() == reading
            if wordLookup[form].length > 0
              [topReading,topEnglish] = wordLookup[form][0]
              if topReading.toLowerCase() != topReading
                wordLookup[form].unshift([reading, english]) # prepend
                continue
              if topEnglish.indexOf('variant of ') == 0
                wordLookup[form].unshift([reading, english]) # prepend
                continue
          wordLookup[form].push([reading, english])
    @wordLookup = wordLookup

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

  getWordList: (sentence) ->
    myself = this
    longestStartWord = (remaining) ->
      if myself.getEnglishForWord(remaining) != ''
        return remaining
      if remaining.length == 1
        return remaining
      return longestStartWord(remaining[0...remaining.length-1])
    words = []
    i = 0
    while i < sentence.length
      nextWord = longestStartWord(sentence[i..])
      words.push(nextWord)
      i += nextWord.length
    return words

root.ChineseDict = ChineseDict

