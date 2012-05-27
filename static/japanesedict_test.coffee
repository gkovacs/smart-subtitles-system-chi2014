fs = require 'fs'
root = exports ? this
print = console.log

japanesedict = require './japanesedict'

main = ->
  dictText = fs.readFileSync('edict2_full.txt', 'utf8')
  jdict = new japanesedict.JapaneseDict(dictText)
  #jdict.getGlossForSentence('拳銃所持容疑:警視庁、組幹部ら逮捕', print)
  #jdict.getGlossForSentence('その１０倍もの神経細胞支持する細胞があります', print)
  #jdict.getGlossForSentence('お嬢さんの病気は何らかの理由で小脳が萎縮し', print)
  #jdict.getGlossForSentence('その中で体を自由にスムーズに動かす働きをしているのが', print)
  #jdict.getGlossForSentence('病気はどうして私を選んだのだろう', print)
  #jdict.getGlossForSentence('それらの神経細胞は中枢神経と末梢神経に分けられ', print)
  jdict.getGlossForSentence('特別じゃない  ただ特別な病気に選ばれてしまった 少女の記録', print)

main() if require.main is module
