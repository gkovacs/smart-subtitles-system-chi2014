root = exports ? this
print = console.log

redis = require 'redis'
client = redis.createClient()

sys = require 'util'
child_process = require 'child_process'

parseAdsoOutput = (stdout) ->
  words = []
  for line in stdout.split('\n')
    [word, pinyin, english, pos] = line.split('\t')
    words.push([word, pinyin, english])
  return words

escapeshell = (cmd) ->
  return '"'+cmd.replace(/(["\s'$`\\])/g,'\\$1')+'"'

getWordsPinyinEnglishCached = (text, callback) ->
  client.get('adsovocab|' + text, (err, reply) ->
    if reply?
      callback(parseAdsoOutput(reply))
    else
      command = "./adso --vocab -i " + escapeshell(text)
      child_process.exec(command, (error, stdout, stderr) ->
        stdout = stdout.trim()
        client.set('adsovocab|' + text, stdout)
        callback(parseAdsoOutput(stdout))
      )
  )

root.getWordsPinyinEnglishCached = getWordsPinyinEnglishCached

main = ->
  text = process.argv[2]
  print text
  getWordsPinyinEnglishCached(text, (words) ->
    for [word,pinyin,english] in words
      console.log word
      console.log pinyin
      console.log english
  )

main() if require.main is module
