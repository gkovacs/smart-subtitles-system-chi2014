root = exports ? this
print = console.log

applyToneToVowel = (vowel, num) ->
  --num
  if vowel == 'a'
    return ['ā', 'á', 'ǎ', 'à', 'a'][num]
  if vowel == 'i'
    return ['ī', 'í', 'ǐ', 'ì', 'i'][num]
  if vowel == 'e'
    return ['ē', 'é', 'ě', 'è', 'e'][num]
  if vowel == 'o'
    return ['ō', 'ó', 'ǒ', 'ò', 'o'][num]
  if vowel == 'u'
    return ['ū', 'ú', 'ǔ', 'ù', 'u'][num]
  if vowel == 'ü'
    return ['ǖ', 'ǘ', 'ǚ', 'ǜ', 'ü'][num]

getToneNumber = (word) ->
  toneNum = word[-1..-1]
  if toneNum in ['1','2','3','4']
    return parseInt(toneNum)
  else
    return 5

toneNumberToMarkSingle = (word) ->
  word = word.trim()
  toneNum = word[-1..-1]
  if toneNum in ['1','2','3','4','5']
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
      english = line[line.indexOf('/')+1...-1]
      if not wordLookup[trad]? or wordLookup[trad][1].toLowerCase() != wordLookup[trad][1]
        wordLookup[trad] = [pinyin, english]
      if not wordLookup[simp]? or wordLookup[simp][1].toLowerCase() != wordLookup[simp][1]
        wordLookup[simp] = [pinyin, english]
    processLine(line) for line in dictText.split('\n')
    @wordLookup = wordLookup

  getWordList: (sentence) ->
    return sentence.split('') # TODO

  getPinyinForWord: (word) ->
    res = this.wordLookup[word]
    if res? and res.length == 2
      return res[0]
    else
      return ''

  getEnglishForWord: (word) ->
    res = this.wordLookup[word]
    if res? and res.length == 2
      return res[1]
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
root.getToneNumber = getToneNumber
