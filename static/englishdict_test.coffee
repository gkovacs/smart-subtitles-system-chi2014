fs = require 'fs'
print = console.log
englishdict = require './englishdict'

main = ->
  dictText = fs.readFileSync('engdict-opted.html', 'utf8')
  edict = new englishdict.EnglishDict(dictText)
  #print edict.splitWord('dog-pre"sgk-school sgdlk eating.out')
  #print edict.getWordList('dog-pre"sgk-school sgdlk eating.out')
  #print edict.splitWord('9111')
  #print edict.getWordList('The day after 9111,')
  print edict.getDefnForWord('flew')
  #print edict.getReferenceInDefinition('(<I>imp.</I>) of Fly')

main() if require.main is module
