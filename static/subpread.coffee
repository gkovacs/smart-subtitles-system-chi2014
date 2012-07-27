root = exports ? this
print = console.log

jsdom = require 'jsdom'

toDeciSeconds = (time) ->
  time = time.split(',').join('.')
  [hour,min,sec] = time.split(':')
  hour = parseFloat(hour)
  min = parseFloat(min)
  sec = parseFloat(sec)
  return Math.round((hour*3600 + min*60 + sec)*10)

class SubpRead
  constructor: (subtitleText, directory) ->
    @subtitleText = subtitleText
    document = jsdom.jsdom(subtitleText)
    timesAndSubtitles = [] # start,end,subtitle
    timeToSubtitle = {}
    for x in document.getElementsByTagName('subtitle')
      start = toDeciSeconds(x.getAttribute('start'))
      stop = toDeciSeconds(x.getAttribute('stop'))
      subtitle = x.getElementsByTagName('image')[0].textContent
      timesAndSubtitles.push([start, stop, directory + subtitle])
    for triplet in timesAndSubtitles
      [startTime,endTime,lineContents] = triplet
      if startTime > lastStartTime
        lastStartTime = startTime
      while startTime < endTime + 50
        timeToSubtitle[startTime] = lineContents
        ++startTime
    @timeToSubtitle = timeToSubtitle
    @timesAndSubtitles = timesAndSubtitles
    @lastStartTime = lastStartTime

  subtitleAtTime: (deciSec) ->
    retv = this.timeToSubtitle[deciSec]
    if retv
      retv
    else
      ''

root.SubpRead = SubpRead
root.toDeciSeconds = toDeciSeconds
