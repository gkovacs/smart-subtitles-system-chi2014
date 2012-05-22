root = exports ? this
print = console.log

class SubtitleRead
  constructor: (subtitleText) ->
    @subtitleText = subtitleText
    timeToSubtitle = {}
    timesAndSubtitles = [] # start,end,subtitle
    awaitingTime = true
    startTime = 0.0
    endTime = 0.0
    lineContents = ''
    processLine = (line) ->
      line = line.trim()
      if line == ''
        if lineContents != ''
          timesAndSubtitles.push([startTime,endTime,lineContents])
        awaitingTime = true
        lineContents = ''
      else if awaitingTime
        if line.indexOf(' --> ') != -1
          awaitingTime = false
          [startTime, endTime] = line.split(' --> ')
          toSeconds = (time) ->
            if time.indexOf(',') != -1
              time = time[0...time.indexOf(',')]
            [hour,min,sec] = time.split(':')
            hour = parseInt(hour)
            min = parseInt(min)
            sec = parseInt(sec)
            Math.round(hour*3600 + min*60 + sec)
          startTime = toSeconds(startTime)
          endTime = toSeconds(endTime)
          awaitingTime = false
      else
        lineContents = (lineContents + '\n' + line).trim()
    processLine(line) for line in subtitleText.split('\n')
    
    processSubtitle = (triplet) ->
      [startTime,endTime,lineContents] = triplet
      while startTime < endTime
        timeToSubtitle[startTime] = lineContents
        ++startTime
    processSubtitle(triplet) for triplet in timesAndSubtitles
    @timeToSubtitle = timeToSubtitle
    @timesAndSubtitles = timesAndSubtitles

  subtitleAtTime: (sec) ->
    retv = this.timeToSubtitle[sec]
    if retv
      retv
    else
      ''

root.SubtitleRead = SubtitleRead

