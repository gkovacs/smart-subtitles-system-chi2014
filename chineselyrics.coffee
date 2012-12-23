fs = require 'fs'
iconv_lite = require 'iconv-lite'
#Iconv = require('iconv').Iconv
$ = require 'jQuery'
http_get = require 'http-get'

client_utils = require './static/client'

parseTime = (timestamp) ->
  if timestamp[..0] != '['
    return [NaN, NaN]
  if timestamp[-1..] != ']'
    return [NaN, NaN]
  [min,sec] = timestamp[1...-1].split(':')
  return [parseInt(min), parseFloat(sec)]

main = ->
  songurl = process.argv[2] ? 'http://www.5ilrc.com/Song_390066.html'
  await
    http_get.get({url: songurl, encoding: 'binary'}, defer(err, dlData))
  pagedata = dlData.buffer
  #console.log pagedata

  #filebuf = fs.readFileSync('花又开好了.html', encoding='binary')
  fileconts = iconv_lite.encode(pagedata, 'binary')
  fileconts = iconv_lite.decode(fileconts, 'gbk')
  #console.log fileconts

  lyrics = null
  for x in $(fileconts).find('td.text')
    text = $(x).text()
    if text.indexOf('[ti:') == -1 or text.indexOf('[ar:') == -1
      continue
    lyrics = text
    break
  times_and_texts = []
  for line in lyrics.split('[').join('\n[').split('\n')
    if line.indexOf('www.5ilrc.com') != -1
      continue
    timestamp = line[...'[00:00.00]'.length]
    lyric = line['[00:00.00]'.length..].trim()
    if lyric == ''
      continue
    if lyric.indexOf('QQ：') == 0
      continue
    [min,sec] = parseTime(timestamp)
    if isNaN(min) or isNaN(sec)
      continue
    times_and_texts.push [60*min + sec, lyric]
  for entry,i in times_and_texts
    [starttime,text] = entry
    console.log i+1
    endtime = starttime + 10.0
    if i+1 < times_and_texts.length
      endtime = times_and_texts[i+1][0]
    [hr,min,sec,msec] = client_utils.toHourMinSecMillisec(starttime)
    startstring = [hr,min,sec].join(':')+'.'+msec
    [hr,min,sec,msec] = client_utils.toHourMinSecMillisec(endtime)
    endstring = [hr,min,sec].join(':')+'.'+msec
    console.log startstring + ' --> ' + endstring
    console.log text
    console.log ''

main() if require.main is module

