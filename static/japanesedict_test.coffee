root = exports ? this
print = console.log

japanesedict = require './japanesedict'

main = ->
  jdict = new japanesedict.JapaneseDict()
  jdict.getGlossForSentence('前大阪市議:事務所家賃を二重計上', (glossText) -> print glossText)

main() if require.main is module
