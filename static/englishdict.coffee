root = exports ? this
print = console.log

lowercase = 'abcdefghijklmnopqrstuvwxyz'
uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
letters = lowercase + uppercase

class EnglishDict
  constructor: (dictText) ->
    wordLookup = {} # word => ['', definition]
    for line in dictText.split('\n')
      line = line.trim()
      word = line[0...line.indexOf('</B>')]
      word = word[line.indexOf('<B>')+3..].trim().toLowerCase()
      defn = line[line.indexOf('</B>')+4...-4].trim()
      if not wordLookup[word]?
        wordLookup[word] = []
      t = wordLookup[word]
      t[t.length] = defn
    nwordLookup = {}
    for word,defnl of wordLookup
      wordReferences = []
      for defn in defnl
        reference = @getReferenceInDefinition(defn)
        if reference != '' and reference not in wordReferences
          wordReferences.push(reference)
      output = defnl[..]
      for reference in wordReferences
        output.push('<B>' + reference + ':</B>')
        refdefnl = wordLookup[reference]
        if refdefnl?
          for refdefn in refdefnl
            output.push(refdefn)
      nwordLookup[word] = output.join('\n<BR/>')
    @wordLookup = nwordLookup

  getDefnForWord: (word) ->
    if word.length == 0
      return ''
    word = word.toLowerCase()
    res = this.wordLookup[word]
    if res?
      return res
    else
      lastchar = word[-1..-1]
      if lastchar not in letters
        return @getDefnForWord(word[...-1])
      firstchar = word[0..0]
      if firstchar not in letters
        return @getDefnForWord(word[1..])
      suffixes = ['ing', 's', 'es', 'ed', 'er']
      for suf in suffixes
        slen = suf.length
        if word[-slen..] == suf
          return @getDefnForWord(word[...-slen])
      return ''

  getReferenceInDefinition: (defn) ->
    defn = defn[defn.indexOf(')')+1..].trim()
    if defn.length <= 1
      return ''
    if defn[-1..-1] == '.'
      defn = defn[...-1]
    wordsInDefn = defn.split(' ')
    if wordsInDefn.length == 2 and wordsInDefn[0].toLowerCase() == 'of'
      return wordsInDefn[1].toLowerCase()
    else if wordsInDefn.length == 3 and wordsInDefn[1].toLowerCase() == 'of'
      return wordsInDefn[2].toLowerCase()
    else
      return ''

  splitWordGetForwardIdxs: (word) ->
    splitIdxs = []
    startIdx = 0
    for i in [0...word.length]
      if (word[i] not in letters) and (@getDefnForWord(word[startIdx...i]) != '')
        splitIdxs.push(i)
        startIdx = i+1
    return [startIdx, splitIdxs]
  
  splitWordGetBackIdxs: (word) ->
    splitIdxs = []
    endIdx = word.length
    for i in [word.length-1..0]
      if (word[i] not in letters) and (@getDefnForWord(word[i...endIdx]) != '')
        splitIdxs.push(i)
        endIdx = i
    return splitIdxs

  splitWord: (word) ->
    if word.length <= 1
      return [word]
    [startIdx, startIdxs] = @splitWordGetForwardIdxs(word)
    remainingWord = word[startIdx..]
    endIdxs = @splitWordGetBackIdxs(word[startIdx..])
    endIdxs = endIdxs.reverse()
    endIdxs = (x+startIdx for x in endIdxs)
    splitIdxs = startIdxs.concat(endIdxs)
    output = []
    previ = 0
    for i in splitIdxs
      output.push(word[previ...i])
      output.push(word[i])
      previ = i+1
    if previ != word.length
      output.push(word[previ..])
    return output

  getWordList: (sentence) ->
    output = []
    for x in sentence.split(' ')
      if @getDefnForWord(x) != ''
        output.push(x)
      else
        for y in @splitWord(x)
          output.push(y)
      output.push(' ')
    return output

root.EnglishDict = EnglishDict

