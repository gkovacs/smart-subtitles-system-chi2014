root = exports ? this
print = console.log

callOnceMethodAvailable = (method, callback) ->
  if now[method]?
    callback()
  else
    setTimeout(() ->
      callOnceMethodAvailable(method, callback)
    , 300)

root.callOnceMethodAvailable = callOnceMethodAvailable
