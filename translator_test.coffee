root = exports ? this
print = console.log

translator = require './translator'

main = () ->
	word = process.argv[2] ? '说'
	await
	  translator.getTranslations(word, 'zh-CHS', 'en', defer(output))
	print output

main() if require.main is module
