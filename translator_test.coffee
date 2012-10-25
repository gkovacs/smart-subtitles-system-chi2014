root = exports ? this
print = console.log

translator = require './translator'

main = () ->
	await
	  translator.getTranslations('说', 'zh-CHS', 'en', defer(output))
	print output

main() if require.main is module