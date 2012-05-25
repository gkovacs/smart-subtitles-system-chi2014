root = exports ? this
print = console.log

japanesedict = require './japanesedict'

main = ->
  jdict = new japanesedict.JapaneseDict()
  #jdict.getGlossForSentence('拳銃所持容疑:警視庁、組幹部ら逮捕', print)
  #jdict.getGlossForSentence('その１０倍もの神経細胞支持する細胞があります', print)
  #jdict.getGlossForSentence('お嬢さんの病気は何らかの理由で小脳が萎縮し', print)
  jdict.getGlossForSentence('その中で体を自由にスムーズに動かす働きをしているのが', print)

main() if require.main is module
