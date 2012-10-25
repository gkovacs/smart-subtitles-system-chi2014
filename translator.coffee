root = exports ? this
print = console.log

mstranslator = require 'mstranslator'
fs = require 'fs'

clientText = fs.readFileSync('client_id_and_secret.txt', 'utf8').trim()
[clientID, clientSecret] = clientText.split('\n')

transclient = new mstranslator({client_id: clientID, client_secret: clientSecret})

is_initialized = false

initialize_token = (callback) ->
  if is_initialized == true
  	callback()
  	return
  transclient.initialize_token(() ->
  	is_initialized = true
  	callback()
  )

getTranslations = (fromtext, fromlanguage, tolanguage, callback) ->
  client.get('bing_en_to_zhs_j5|' + fromtext, (err, reply) ->
	  if reply != null
	    callback(JSON.parse(reply))
	  else
	    initialize_token(() ->
	      transclient.getTranslations({text: fromtext, from: fromlanguage, to: tolanguage, maxTranslations: 5}, (err2, translated_text) ->
	        client.set('bing_en_to_zhs_j5|' + fromtext, JSON.stringify(translated_text.Translations))
	        callback(translated_text.Translations)
	      )
	    )
  )

redis = require 'redis'
client = redis.createClient()

print 'done loading'

initialize_token(() ->
  #transclient.getLanguagesForTranslate((err, data) ->
  #  print data
  #)
)

#getTranslations = (fromtext, fromlanguage, tolanguage, callback) ->
#  client.translate({text: fromtext, from: fromlanguage, to: tolanguage}, callback)

root.getTranslations = getTranslations