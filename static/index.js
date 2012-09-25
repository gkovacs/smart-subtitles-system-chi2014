sub = {}
//cdict = {}

audioQueue = []

subLanguage = 'zh'

function prevButtonPressed() {
  var vid = $('video')[0]
  vid.pause()
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

function setHoverTrans(wordid, hovertext) {
$('.'+ wordid).hover(function() {
  var vid = $('video')[0]
  vid.pause()
  $('.hoverable').css('background-color', '')
  $('.'+ wordid).css('background-color', 'yellow')
  if (subLanguage == 'en') {
    $('#translation').html(hovertext)
  } else {
    $('#translation').text(hovertext)
  }
})
}

function nextAudioItem() {
  console.log(audioQueue)
  if (audioQueue.length > 0) {
    $('audio')[0].src = audioQueue.pop()
    $('audio')[0].play()
  }
}

function setClickPronounceEN(wordid, word) {
$('.'+ wordid).click(function() {
  var vid = $('video')[0]
  vid.pause()
  now.getPrononciation(word.toLowerCase(), function(nword, prononc, prurl) {
    $('.'+wordid+'.pinyinspan').html(prononc)
    audioQueue = [prurl]
    nextAudioItem()
  })
})
}

function setClickPronounceZH(wordid, pinyin) {
$('.'+ wordid).click(function() {
  var vid = $('video')[0]
  vid.pause()
  var nqueue = []
  var pinyinWords = pinyin.split(' ')
  for (var i = 0; i < pinyinWords.length; ++i) {
    var piny = pinyinWords[i].toLowerCase()
    var tonenum = getToneNumber(piny)
    if (tonenum == 5)
      tonenum = 1
    var notonemark = removeToneMarks(piny) + tonenum
    nqueue.push('http://transgame.csail.mit.edu/pinyin/' + notonemark + '.mp3')
  }
  nqueue.reverse()
  audioQueue = nqueue
  nextAudioItem()
})
}

/*
function getTransAndSetHover(word) {
  now.getEnglish(word, function(english) {
    setHoverTrans(word, english)
  })
}
*/

function setNewSubPix(subpixPath) {
if (subpixPath == '')
  subpixPath = 'blank.png'
$('#subpDisplay').attr('src', subpixPath)
}

function setNewSubtitles(annotatedWordList) {
console.log(annotatedWordList.toString())
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
var pinyinspan = '<td style="font-size: large; text-align: center;" class="' + randid + ' hoverable pinyinspan">' + coloredSpans.join(' ') + '</td>'
var wordspan = '<td style="font-size: xx-large" class="' + randid + ' hoverable wordspan">' + word + '</td>'
if (word == ' ') {
  wordspan = '<td style="font-size: xx-small">　</td>'
}

pinyinRow.push(pinyinspan)
wordRow.push(wordspan)

}

nhtml.push('<col>' + pinyinRow.join('') + '</col>')
nhtml.push('<col>' + wordRow.join('') + '</col>')

nhtml.push('</table>')

$('#caption').html(nhtml.join(''))

for (var i = 0; i < annotatedWordList.length; ++i) {
  var word = annotatedWordList[i][0]
  var pinyin = annotatedWordList[i][1]
  var english = annotatedWordList[i][2]
  var randid = wordToId[word]
  setHoverTrans(randid, english)
  if (subLanguage == 'en') {
    setClickPronounceEN(randid, word)
  } else if (subLanguage == 'zh') {
    setClickPronounceZH(randid, pinyin)
  }
}

}

function onTimeChanged(s) {
now.getAnnotatedSubAtTime(Math.round(s.currentTime*10), setNewSubtitles)
now.getSubPixAtTime(Math.round(s.currentTime*10), setNewSubPix)
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

function flipPause() {
  var vid = $('video')[0]
  if (vid.paused)
    vid.play()
  else
    vid.pause()
}

function videoPlaying() {
$('#playPauseButton').text('Pause (Space)')
$('#prevLineButton').show()
$('#nextLineButton').show()
}

function videoPaused() {
$('#playPauseButton').text('Play (Space)')
$('#prevLineButton').show()
$('#nextLineButton').show()
}

$(document).click(function(x) {
var vid = $('video')[0]
var mouseCoords = relMouseCoords(x, vid)
if (mouseCoords.y > $('video').height() - 30 || mouseCoords.x > $('video').width()) return true
if (vid.paused)
  vid.play()
else
  vid.pause()
return false
})

function checkKey(x) {
  var vid = $('video')[0]
  if (x.keyCode == 32) { // space
    if (vid.paused)
      vid.play()
    else
      vid.pause()
    x.preventDefault()
    return false
  } else if (x.keyCode == 37) { // left arrow
    if (x.ctrlKey) {
      prevButtonPressed()
    } else {
      vid.currentTime -= 5
    }
    x.preventDefault()
    return false
  } else if (x.keyCode == 39) { // right arrow
    if (x.ctrlKey) {
      nextButtonPressed()
    } else {
      vid.currentTime += 5
    }
    x.preventDefault()
    return false
  }
}

$(document).keydown(checkKey)

function startPlayback() {
  if (isLocalFile()) {
    var file = $('#videoInputFile')[0].files[0]
    var type = file.type
    var videoNode = $('video')[0]
    var canPlay = videoNode.canPlayType(type)
    canPlay = (canPlay === '' ? 'no' : canPlay)
    var isError = canPlay === 'no'
    var URL = window.URL
    if (!URL)
      URL = window.webkitURL
    var fileURL = URL.createObjectURL(file)
    videoNode.src = fileURL
  } else {
    var videoSource = $('#videoInputURL').val().trim()
    $('video')[0].src = videoSource
  }
  var subtitleText = $('#subtitleInput').val().trim()
  $('#inputRegion').hide()
  $('#viewingRegion').show()
  if (subtitleText.indexOf('\n') == -1) { // this is a URL, not the subtitle text
    if (subtitleText.indexOf('Loading subtitles from ') == 0)
      subtitleText = subtitleText.substring('Loading subtitles from '.length)
    now.initializeSubtitle(subtitleText, subLanguage)
  } else { // this is the subtitle text
    now.initializeSubtitleText(subtitleText, subLanguage)
  }
  var subpixSource = getUrlParameters()['subpix']
  if (subpixSource != null) {
    now.initializeSubPix(subpixSource)
  }
}

function isLocalFile() {
  return ($('#urlOrFile').val() == 'file')
}

function loadVideo(videourl, suburl) {
  if (videourl.indexOf('{m4v|webm}') != -1) {
    if (Modernizr.video.webm && !Modernizr.video.h264) {
      videourl = videourl.replace('{m4v|webm}', 'webm')
    } else {
      videourl = videourl.replace('{m4v|webm}', 'm4v')
    }
  }
  if (videourl.indexOf('{mp4|webm}') != -1) {
    if (Modernizr.video.webm && !Modernizr.video.h264) {
      videourl = videourl.replace('{mp4|webm}', 'webm')
    } else {
      videourl = videourl.replace('{mp4|webm}', 'mp4')
    }
  }
  $('#urlOrFile').val('url')
  urlOrFileChanged()
  $('#videoInputURL').val(videourl)
  $('#subtitleInput').val('')
  textChanged()
  $('#subtitleInput').val('Loading subtitles from ' + suburl)
  now.downloadSubtitleText(suburl, function(subText) {
    $('#subtitleInput').val(subText)
    textChanged()
  })
}

function urlOrFileChanged() {
  if (isLocalFile()) {
    $('#videoInputURL').hide()
    $('#videoInputFile').show()
  } else {
    $('#videoInputFile').hide()
    $('#videoInputURL').show()
  }
}

function subtitleUploaded() {
var reader = new FileReader()
reader.onloadend = function( ){
  $('#subtitleInput').val(reader.result)
  textChanged()
}
var srtfile = $('#srtInputFile')[0].files[0]
reader.readAsText(srtfile)
}

function textChanged() {
  if (isLocalFile()) {
    if ($('#videoInputFile').val() && $('#subtitleInput').val()) {
      $('#startPlaybackButton')[0].disabled = false
    } else {
      $('#startPlaybackButton')[0].disabled = true
    }
  } else {
    if ($('#videoInputURL').val() && $('#subtitleInput').val()) {
      $('#startPlaybackButton')[0].disabled = false
    } else {
      $('#startPlaybackButton')[0].disabled = true
    }
  }
}

function onVideoError(s) {
  var videoPlaybackError = s.error
  if (videoPlaybackError) {
    var videoSource = s.src
    var errorMessage = ''
    if (videoPlaybackError.code == 0) errorMessage = 'MEDIA_ERR_ABORTED - fetching process aborted by user'
    if (videoPlaybackError.code == 1) errorMessage = 'MEDIA_ERR_NETWORK - error occurred when downloading'
    if (videoPlaybackError.code == 3) errorMessage = 'MEDIA_ERR_DECODE - error occurred when decoding'
    if (videoPlaybackError.code == 4) errorMessage = 'MEDIA_ERR_SRC_NOT_SUPPORTED - audio/video format not supported by browser'
    var printableError =  JSON.stringify(videoPlaybackError, null, 4)
    $('#errorRegion').text('Error playing ' + videoSource + ': ' + errorMessage + ' ' + printableError)
  }
}

function getUrlParameters() {
var map = {};
var parts = window.location.href.replace(/[?&]+([^=&]+)=([^&]*)/gi, function(m,key,value) {
map[key] = value;
});
return map; 
}


