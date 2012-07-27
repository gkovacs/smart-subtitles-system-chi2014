fs = require 'fs'
print = console.log
subpread = require './subpread'

main = ->
  #subtext = fs.readFileSync('shaolin.srt', 'utf8')
  #sr = new subtitleread.SubtitleRead(subtext)
  #print sr.timeToSubtitle
  #print sr.subtitleAtTime(9)
  #print subtitleread.toDeciSeconds('00:09:00,808')
  subtext = fs.readFileSync('subt/1_track5.xml')
  sr = new subpread.SubpRead(subtext, 'subt/')
  print sr.subtitleAtTime(820)

main() if require.main is module
