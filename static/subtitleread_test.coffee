fs = require 'fs'
print = console.log
subtitleread = require './subtitleread'

main = ->
  subtext = fs.readFileSync('shaolin.srt', 'utf8')
  sr = new subtitleread.SubtitleRead(subtext)
  print sr.timeToSubtitle

main() if require.main is module
