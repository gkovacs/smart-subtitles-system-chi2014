root = exports ? this
print = console.log

callOnceMethodAvailable = (method, callback) ->
  if now[method]?
    callback()
  else
    setTimeout(() ->
      callOnceMethodAvailable(method, callback)
    , 300)

root.toHourMinSecMillisec = (seconds) ->
  hours = Math.floor(seconds / 3600)
  seconds -= hours * 3600
  minutes = Math.floor(seconds / 60)
  seconds -= minutes * 60
  seconds_whole = Math.floor(seconds)
  milliseconds = (seconds - seconds_whole) * 1000
  milliseconds = Math.round(milliseconds)
  return [ljust(hours.toString(), 2, '0'), ljust(minutes.toString(), 2, '0'), ljust(seconds_whole.toString(), 2, '0'), rjust(milliseconds.toString(), 3, '0')]

root.toHourMinSec = (seconds) ->
  hours = Math.floor(seconds / 3600)
  seconds -= hours * 3600
  minutes = Math.floor(seconds / 60)
  seconds -= minutes * 60
  seconds = Math.round(seconds)
  return [ljust(hours.toString(), 2, '0'), ljust(minutes.toString(), 2, '0'), ljust(seconds.toString(), 2, '0')]

ljust = (str, length, padchar=' ') ->
  fill = []
  while fill.length + str.length < length
  	fill.push(padchar)
  return fill.join('') + str

rjust = (str, length, padchar=' ') ->
  fill = []
  while fill.length + str.length < length
  	fill.push(padchar)
  return str + fill.join('')

replaceAll = (str, from, to) ->
  return str.split(from).join(to)

root.escapeHtmlQuotes = (str) ->
  replacements = [['&', '&amp;'], ['>', '&gt;'], ['<', '&lt;'], ['"', '&quot;'], ["'", '&#8217;']]
  for [from,to] in replacements
    str = replaceAll(str, from, to)
  return str

root.callOnceMethodAvailable = callOnceMethodAvailable
root.ljust = ljust
root.rjust = rjust
