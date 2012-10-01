fs = require 'fs'
print = console.log
subtitleread = require './subtitleread'

main = ->
  #subtext = fs.readFileSync('shaolin.srt', 'utf8')
  #sr = new subtitleread.SubtitleRead(subtext)
  #print sr.timeToSubtitle
  #print sr.subtitleAtTime(9)
  #print subtitleread.toDeciSeconds('00:09:00,808')
  sr = new subtitleread.SubtitleRead("00:00:01 --> 00:00:03\n一\n\n00:00:04 --> 00:00:06\n二\n\n00:00:07 --> 00:00:09\n三")
  print sr
  print sr.getTimesAndSubtitles()

main() if require.main is module
