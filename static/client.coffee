root = exports ? this
print = console.log

callOnceMethodAvailable = (method, callback) ->
  if now[method]?
    callback()
  else
    setTimeout(() ->
      callOnceMethodAvailable(method, callback)
    , 300)

root.toHourMinSec = (seconds) ->
  hours = Math.floor(seconds / 3600)
  seconds -= hours * 3600
  minutes = Math.floor(seconds / 60)
  seconds -= minutes * 60
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

root.callOnceMethodAvailable = callOnceMethodAvailable
root.ljust = ljust
root.rjust = rjust
