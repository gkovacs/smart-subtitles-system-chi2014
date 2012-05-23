sub = {}
//cdict = {}

function prevButtonPressed() {
  var vid = $('video')[0]
  //vid.pause()
  curtime = Math.round(vid.currentTime*10)
  now.getPrevDialogStartTime(curtime, function(time) {
    vid.currentTime = time/10
  })
}

function nextButtonPressed() {
  var vid = $('video')[0]
  //vid.pause()
  curtime = Math.round(vid.currentTime*10)
  now.getNextDialogStartTime(curtime, function(time) {
    vid.currentTime = time/10
  })
}

function setHoverTrans(word, hovertext) {
$('.'+ word).hover(function() {
  var vid = $('video')[0]
  vid.pause()
  $('.hoverable').css('background-color', '')
  $('.'+ word).css('background-color', 'yellow')
  $('#translation').text(hovertext)
})
}

/*
function getTransAndSetHover(word) {
  now.getEnglish(word, function(english) {
    setHoverTrans(word, english)
  })
}
*/

function setNewSubtitles(annotatedWordList) {
//if (annotatedWordList.length == 0) return
$('#translation').text('')
var nhtml = []

var wordToId = {}

nhtml.push('<table border="0" cellspacing="0">')

var pinyinRow = []
var wordRow = []

for (var i = 0; i < annotatedWordList.length; ++i) {
var word = annotatedWordList[i][0]
var pinyin = annotatedWordList[i][1]
var english = annotatedWordList[i][2]

if (wordToId[word] == null)
  wordToId[word] = Math.round(Math.random() * 1000000)
var randid = wordToId[word]

coloredSpans = []
var pinyinWords = pinyin.split(' ')
for (var j = 0; j < pinyinWords.length; ++j) {
  var curWord = pinyinWords[j]
  var tonecolor = ['red', '#AE5100', 'green', 'blue', 'black'][getToneNumber(curWord)-1]
  coloredSpans.push('<span style="color: ' + tonecolor + '">' + curWord + '</span>')
}
var pinyinspan = '<td style="font-size: large; text-align: center;" class="' + randid + ' hoverable">' + coloredSpans.join(' ') + '</td>'
var wordspan = '<td style="font-size: xx-large" class="' + randid + ' hoverable">' + word + '</td>'

pinyinRow.push(pinyinspan)
wordRow.push(wordspan)

}

nhtml.push('<col>' + pinyinRow.join('') + '</col>')
nhtml.push('<col>' + wordRow.join('') + '</col>')

nhtml.push('</table>')

$('#caption').html(nhtml.join(''))

for (var i = 0; i < annotatedWordList.length; ++i) {
var word = annotatedWordList[i][0]
var english = annotatedWordList[i][2]
var randid = wordToId[word]
setHoverTrans(randid, english)
}

}

function onTimeChanged(s) {
now.getAnnotatedSubAtTime(Math.round(s.currentTime*10), setNewSubtitles)
}

/*
var curSub = sub.subtitleAtTime(Math.round(currentTime))
var wordsInSub = curSub.split('')

$('#translation').text('')
now.getPinyin(curSub, function(pinyin) {
if (pinyin == '') $('#pinyin').text('')
else $('#pinyin').text(toneNumberToMark(pinyin).toLowerCase())
})


for (var i = 0; i < wordsInSub.length; ++i) {
var word = wordsInSub[i]
nhtml.push('<span class="hoverable" id="' + word + '">' + word + '</span>')
}

$('#caption').html(nhtml.join(''))

for (var i = 0; i < wordsInSub.length; ++i) {
var word = wordsInSub[i]
getTransAndSetHover(word)
}

}
*/

function relMouseCoords(event, htmlelem){
    var totalOffsetX = 0;
    var totalOffsetY = 0;
    var canvasX = 0;
    var canvasY = 0;
    var currentElement = htmlelem;

    do{
        totalOffsetX += currentElement.offsetLeft;
        totalOffsetY += currentElement.offsetTop;
    }
    while(currentElement = currentElement.offsetParent)

    canvasX = event.pageX - totalOffsetX;
    canvasY = event.pageY - totalOffsetY;

    return {x:canvasX, y:canvasY}
}

/*
$('body').mousemove(function(x) {
var vid = $('video')[0]
var mouseCoords = relMouseCoords(x, vid)
if (mouseCoords.y < $('video').height() && mouseCoords.x < $('video').width()) return
vid.pause()
})
*/

$('body').click(function(x) {
var vid = $('video')[0]
var mouseCoords = relMouseCoords(x, vid)
if (mouseCoords.y > $('video').height() || mouseCoords.x > $('video').width()) return
if (vid.paused)
  vid.play()
else
  vid.pause()
})

function checkKey(x) {
  var vid = $('video')[0]
  if (x.keyCode == 32) { // space
    if (vid.paused)
      vid.play()
    else
      vid.pause()
  } else if (x.keyCode == 37) { // left arrow
    if (x.ctrlKey) {
      prevButtonPressed()
    } else {
      vid.currentTime -= 5
    }
  } else if (x.keyCode == 39) { // right arrow
    if (x.ctrlKey) {
      nextButtonPressed()
    } else {
      vid.currentTime += 5
    }
  }
}

$('body').keydown(checkKey)

function getUrlParameters() {
var map = {};
var parts = window.location.href.replace(/[?&]+([^=&]+)=([^&]*)/gi, function(m,key,value) {
map[key] = value;
});
return map; 
}

now.ready(function() {
var urlParams = getUrlParameters()
var videoSource = 'shaolin.m4v'
if (urlParams['video'] != null)
  videoSource = urlParams['video']
$('video')[0].src = videoSource
var subSource = 'shaolin.srt'
if (urlParams['sub'] != null)
  subSource = urlParams['sub']
now.initializeSubtitle(subSource)
})

