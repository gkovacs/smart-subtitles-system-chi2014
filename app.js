
/**
 * Module dependencies.
 */

var fs = require('fs')
var express = require('express')
var ejs = require('ejs')
var app = express.createServer();

var coffeescript = require('coffee-script')
var subtitleread = require('./static/subtitleread')

var nowjs = require('now')
var everyone = nowjs.initialize(app);

app.configure('development', function(){
  app.use(express.errorHandler({ dumpExceptions: true, showStack: true }));
});

app.configure('production', function(){
  app.use(express.errorHandler());
});

app.configure(function(){
  app.set('views', __dirname + '/views');
  app.set('view engine', 'ejs');
  app.use(express.bodyParser());
  app.use(express.methodOverride());
  app.set('view options', { layout: false })
  app.locals({ layout: false })
  app.use(express.static(__dirname + '/static'));
});

app.get('/', function (req, res) {
  res.render('index'); // Where index.ejs is your ejs template
});

everyone.now.getSubText = function(recSubCallback) {
  subtext = fs.readFileSync('static/shaolin.srt', 'utf8')
  recSubCallback(subtext)
}

app.listen(3000);
console.log("Express server listening on port %d in %s mode", app.address().port, app.settings.env);
