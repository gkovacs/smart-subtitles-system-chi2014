root = exports ? this
print = console.log

http_get = require 'http-get'
redis = require 'redis'
client = redis.createClient()

parseGloss = (htmlPage) ->
  output = []
  for line in htmlPage.split('\n')
    skipLine = true
    if line[...8] == '<ul><li>'
      line = line[8..].trim()
      skipLine = false
    else if line[...4] == '<li>'
      line = line[4..].trim()
      skipLine = false
    if skipLine
      continue
    if line[-5..] == '</li>'
      line = line[...-5].trim()
    kanji = line[...line.indexOf('【')].trim()
    line = line[line.indexOf('【')+1..]
    furigana = line[...line.indexOf('】')].trim()
    english = line[line.indexOf('】')+1..].trim()
    if english.lastIndexOf(';') != -1
      english = english[...english.lastIndexOf(';')].trim()
    if english.lastIndexOf('; (P)') != -1
      english = english[...english.lastIndexOf('; (P)')].trim()
    output.push([kanji,furigana,english])
  return output

class JapaneseDict

  getGlossForSentence: (sentence, callback) ->
    client.get('jpgloss|' + sentence, (err, res) ->
      if res? and res != ''
        callback(parseGloss(res))
      else
        glossURL = 'http://www.edrdg.org/cgi-bin/wwwjdic/wwwjdic?9ZIG' + sentence
        print 'fetching: ' + glossURL
        http_get.get({url: glossURL}, (err, dlData) ->
          glossData = dlData.buffer
          callback(parseGloss(glossData))
          client.set('jpgloss|' + sentence, glossData)
        )
    )

root.JapaneseDict = JapaneseDict

