rest = require 'restler'
memoize = require('async').memoize
$ = require 'jQuery'
fs = require 'fs'

client_utils = require './static/client'

getToken = (callback) ->
  clientText = fs.readFileSync('client_id_and_secret_viki.txt', 'utf8').trim()
  [clientID, clientSecret] = clientText.split('\n')
  rest.postJson('http://viki.com/oauth/token', {
    grant_type: 'client_credentials',
    client_id: clientID,
    client_secret: clientSecret,
  }).on('complete', (token, response) ->
	  callback(token)
  )
getToken = memoize(getToken)

getSubs = (series, episode, language, callback) ->
  # series: 7630
  # episode: 65100
  # language: 'en'
	getToken((token) ->
	  rest.get("http://www.viki.com/api/v3/series/#{series}/episodes/#{episode}/subtitles/#{language}.json", {
	    data: {
	    	access_token: token['access_token']
	    	part: 1,
	    }
	  }).on('complete', (data) ->
	  	callback(data)
	  )
	)

getSubsForId = (videoid, language, callback) ->
	# videoid: 195079
	# language: 'en', 'zh'
	rest.get("http://www.viki.com/subtitles/media_resource/#{videoid}/#{language}.json")
	.on('complete', (data) ->
    callback(data)
	)

getEpisodes = (series, callback) ->
	getToken((token) ->
	  rest.get("http://www.viki.com/api/v3/series/#{series}/episodes.json", {
	    data: {
	    	access_token: token['access_token'],
	    }
	  }).on('complete', (data) ->
	    callback(data)
	  )
	)

main = ->
  videoid = process.argv[2] ? 195079
  language = process.argv[3] ? 'en'
  getSubsForId(videoid, language, (data) ->
    subtitles = data.subtitles
    for subline,i in subtitles
      text = subline.content.split(/<[a-zA-Z\/][^>]*>/).join('').trim()
      starttime = subline.start_time / 1000.0
      endtime = subline.end_time / 1000.0
      [hr,min,sec,msec] = client_utils.toHourMinSecMillisec(starttime)
      startstring = [hr,min,sec].join(':')+'.'+msec
      [hr,min,sec,msec] = client_utils.toHourMinSecMillisec(endtime)
      endstring = [hr,min,sec].join(':')+'.'+msec
      console.log(i+1)
      console.log startstring + ' --> ' + endstring
      console.log text
      console.log('')
  )

main() if require.main is module

#getSubs(5840, 56930, 'en', (data) ->
#  console.log data
#)

#getToken((token) -> console.log token)

#getEpisodes(6229, (data) ->
#  console.log data
#)

#getSubs(7630, 65100, 'zh', (data) ->
#  console.log data
#)

###
getToken((token) ->
  rest.get("http://www.viki.com/api/v3/search.json", {
    data: {
    	access_token: token['access_token'],
    	query: "queen",
    }
  }).on('complete', (data) ->
    for x in data.response
    	console.log x
  )
)
###
###
getToken((token) ->
  rest.get("http://www.viki.com/api/v3/series.json", {
    data: {
    	access_token: token['access_token'],
    	origin_country: 'cn',
    	subtitle_language: 'zh',
    }
  }).on('complete', (data) ->
    console.log data
  )
)
###