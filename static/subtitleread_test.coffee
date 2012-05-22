fs = require 'fs'
print = console.log
subtitleread = require './subtitleread'

main = ->
  #subtext = fs.readFileSync('shaolin.srt', 'utf8')
  #sr = new subtitleread.SubtitleRead(subtext)
  #print sr.timeToSubtitle
  #print sr.subtitleAtTime(9)
  print subtitleread.toDeciSeconds('00:09:00,808')

main() if require.main is module
