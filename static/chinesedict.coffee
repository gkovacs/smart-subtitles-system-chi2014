root = exports ? this
print = console.log

applyToneToVowel = (vowel, num) ->
  --num
  if vowel == 'a'
    return ['ā', 'á', 'ǎ', 'à'][num]
  if vowel == 'i'
    return ['ī', 'í', 'ǐ', 'ì'][num]
  if vowel == 'e'
    return ['ē', 'é', 'ě', 'è'][num]
  if vowel == 'o'
    return ['ō', 'ó', 'ǒ', 'ò'][num]
  if vowel == 'u'
    return ['ū', 'ú', 'ǔ', 'ù'][num]
  if vowel == 'ü'
    return ['ǖ', 'ǘ', 'ǚ', 'ǜ'][num]

toneNumberToMarkSingle = (word) ->
  word = word.trim()
  toneNum = word[-1..-1]
  if toneNum in ['1','2','3','4']
    toneNum = parseInt(toneNum)
    word = word[...-1]
  else
    return word
  vow = ['a', 'i', 'e', 'o', 'u', 'ü']
  numVowels = (x for x in word when x in vow).length
  if numVowels == 0
    return word
  firstVowel = (x for x in word when x in vow)[0]
  if numVowels == 1 or firstVowel == 'a' or firstVowel == 'o' or firstVowel == 'e'
    return word.replace(firstVowel, applyToneToVowel(firstVowel, toneNum))
  secondVowel = (x for x in word when x in vow)[1]
  return word.replace(secondVowel, applyToneToVowel(secondVowel, toneNum))

toneNumberToMark = (words) ->
  wordL = words.split(' ')
  wordL = (toneNumberToMarkSingle(word) for word in wordL)
  wordL.join(' ')

class ChineseDict
  constructor: (dictText) ->
    wordLookup = {} # word => [pinyin, definition]
    processLine = (line) ->
      line = line.trim()
      if line[0] == '#'
        return
      trad = line[0...line.indexOf(' ')]
      line = line[line.indexOf(' ')+1..]
      simp = line[0...line.indexOf(' ')]
      line = line[line.indexOf(' ')+1..]
      pinyin = line[line.indexOf('[')+1...line.indexOf(']')]
      #pinyin = toneNumberToMark(pinyin)
      #print simp
      #print trad
      #print pinyin
      if not wordLookup[trad]?
        wordLookup[trad] = pinyin
      if not wordLookup[simp]?
        wordLookup[simp] = pinyin      
    processLine(line) for line in dictText.split('\n')
    @wordLookup = wordLookup
    print this.wordLookup['你好']

  getWordList: (sentence) ->
    return sentence.split('') # TODO

  getPinyinForWord: (word) ->
    res = this.wordLookup[word]
    print word
    if res != null
      return res
    else
      return ''

  getPinyin: (sentence) ->
    wordList = this.getWordList(sentence)
    print wordList
    nwordList = (this.getPinyinForWord(word) for word in wordList)
    print nwordList
    print nwordList.length
    return nwordList.join(' ')

root.ChineseDict = ChineseDict
root.toneNumberToMark = toneNumberToMark
