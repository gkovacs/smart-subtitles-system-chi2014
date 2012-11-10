root = exports ? this
print = console.log

client_utils = require './static/client'

http_get = require 'http-get'
$ = require 'jQuery'

main = ->
  ted_url = process.argv[2]
  # http://www.ted.com/talks/lang/zh/yang_lan.html
  # http://www.ted.com/talks/lang/zh-cn/yang_lan.html
  #print ted_url
  await
    http_get.get({url: ted_url}, defer(err, dlData))
  pagedata = dlData.buffer
  times_and_texts = []
  for x,i in $(pagedata).find('.transcriptLink')
  	seconds = parseInt($(x).attr('href').replace('#', '')) / 1000.0
  	seconds += 15.33
  	text = $(x).text()
  	times_and_texts.push([seconds, text])
 	for x,i in times_and_texts
 	  [starttime, text] = x
    print i+1
    endtime = starttime + 10.0
    if i+1 < times_and_texts.length
      endtime = times_and_texts[i+1][0]
    [hr,min,sec,msec] = client_utils.toHourMinSecMillisec(starttime)
    startstring = [hr,min,sec].join(':')+'.'+msec
    [hr,min,sec,msec] = client_utils.toHourMinSecMillisec(endtime)
    endstring = [hr,min,sec].join(':')+'.'+msec
    print startstring + ' --> ' + endstring
    print text
    print ''
  #	print x
  #	print x.html()

main() if require.main is module
