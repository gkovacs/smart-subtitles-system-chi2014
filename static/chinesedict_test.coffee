fs = require 'fs'
print = console.log
chinesedict = require './chinesedict'

main = ->
  #print chinesedict.toneNumberToMark('hu1 ma3 xian4')
  dictText = fs.readFileSync('cedict_1_0_ts_utf-8_mdbg.txt', 'utf8')
  cdict = new chinesedict.ChineseDict(dictText)
  #print cdict.getPinyinForWord('家')
  #print cdict.getWordList('大家好')
  #print cdict.getPinyin('大家好')
  print cdict.getEnglishForWord('大')

main() if require.main is module
