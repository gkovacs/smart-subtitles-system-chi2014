sub = {}
//cdict = {}

audioQueue = []

subLanguage = 'zh'
targetLanguage = 'vi'

function prevButtonPressed() {
  //var vid = $('video')[0]
  //vid.pause()
  gotoDialog(prevDialogNum - 1)
  //curtime = Math.round(vid.currentTime*10)
  //now.getPrevDialogStartTime(curtime, function(time) {
  //  vid.currentTime = time/10
  //})
}

function nextButtonPressed() {
  //var vid = $('video')[0]
  //vid.pause()
  gotoDialog(prevDialogNum + 1)
  //curtime = Math.round(vid.currentTime*10)
  //now.getNextDialogStartTime(curtime, function(time) {
  //  vid.currentTime = time/10
  //})
}

function clearHoverTrans() {
  $('.currentlyHighlighted').css('background-color', '')
  $('.currentlyHighlighted').removeClass('currentlyHighlighted')
  $('#translation').hide()
}

function placeTranslationText(wordid) {
  var chineseChar = $('.'+ wordid + ':not(.pinyinspan)')
  var pos = chineseChar.offset()
  var width = chineseChar.width()
  var height = chineseChar.height()
  
  //$('#translation').appendTo(chineseChar)
  $('#translation').css({'left': (pos.left) + 'px', 'top': (pos.top + height + 10) + 'px', 'position': 'absolute', }).show()
  //$('#translationTriangle').appendTo(chineseChar)
  $('#translationTriangle').css({'left': (pos.left) + 'px', 'top': (pos.top + height) + 'px', 'position': 'absolute', })//.show()
}

function onWordLeave(wordid) {
  if ($('#translation').attr('translationFor') == wordid)
    $('#translation').hide()
  $($('.'+ wordid)).css('background-color', '')
  $($('.'+ wordid)).removeClass('currentlyHighlighted')
}

function onWordHover(wordid) {
  //var vid = $('video')[0]
  //vid.pause()
  console.log(wordid)
  clearHoverTrans()
  placeTranslationText(wordid)

  $($('.'+ wordid)).css('background-color', 'yellow')
  $($('.'+ wordid)).addClass('currentlyHighlighted')

  $('#translation').attr('translationFor', wordid)

  var hovertext = $('#WS'+ wordid).attr('hovertext')

  //$('.'+ wordid).css()
  if (subLanguage == 'en') {
    //$('#translation').html(hovertext)
    $('#translation').text(hovertext)
  } else {
    if (hovertext.indexOf('/') != -1) {
      hovertext = hovertext.slice(0, hovertext.indexOf('/'))
    }
    $('#translation').text(hovertext)
    $('#translation').attr('isFullTranslation', 'false')
  }
}

/*
function setHoverTrans(wordid, hovertext) {
$('.'+ wordid).hover(function() {
  onWordHover(wordid)
})
*/
/*
$('.'+ wordid).mouseout(function() {
  $($('.'+ wordid)).css('background-color', '')
  $('#translation').text('')
  $('#translationTriangle').hide()
})
*/

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

prevDialogNum = -1

dialogStartTimesDeciSeconds = []

function wordClicked(dialogNum) {
  var pd = prevDialogNum
  gotoDialog(dialogNum)
  var vid = $('video')[0]
  if (dialogNum < pd) {
    vid.pause()
  } else {
    vid.play()
  }
}

function gotoDialog(dialogNum, dontanimate) {
  gotoDialogNoVidSeek(dialogNum, dontanimate)
  $('video')[0].currentTime = dialogStartTimesDeciSeconds[dialogNum] / 10
}

gotoDialogInProgress = false

function gotoDialogNoVidSeek(dialogNum, dontanimate) {
  if (dialogNum < 0 || dialogNum >= dialogStartTimesDeciSeconds.length) return
  if (dialogNum == prevDialogNum) return
  gotoDialogInProgress = true
  clearHoverTrans()
  
  location.hash = dialogNum.toString()
  
  $('.pysactive').css('font-size', '18px')
  $('.pysactive').removeClass('pysactive')
  $('.wsactive').css('font-size', '32px')
  $('.wsactive').removeClass('wsactive')
  $('.tbactive').hide()
  $('.tbactive').css('font-size', '32px')
  $('.tbactive').removeClass('tbactive')
  $('.pys' + dialogNum).css('font-size', '28px')
  $('.pys' + dialogNum).addClass('pysactive')
  $('.ws' + dialogNum).css('font-size', '48px')
  $('.ws' + dialogNum).addClass('wsactive')
  $('.tb' + dialogNum).css('font-size', '48px')
  $('.tb' + dialogNum).addClass('tbactive')
  $('.tb' + dialogNum).show()
  //$('#dialogStart' + prevDialogNum).css('background-color', 'black')
  //$('#dialogStartPY' + prevDialogNum).css('background-color', 'black')
  //$('#dialogStart' + dialogNum).css('background-color', 'darkgreen')
  //$('#dialogStartPY' + dialogNum).css('background-color', 'darkgreen')
  prevDialogNum = dialogNum
  var videoHeight = $('video')[0].videoHeight
  var videoBottom = $('video').offset().top + videoHeight
  var windowBottom = $('#bottomOfScreen').offset().top
  var offset = $('#whitespaceS' + dialogNum).offset()
  //var width = $('#dialogEndSpaceWS' + dialogNum).offset().left - $('#dialogStartSpaceWS' + dialogNum).offset().left// - $('#dialogStartSpaceWS' + dialogNum).width()
  //var videoOffset = $('video').offset()
  //var videoWidth = $('video')[0].videoWidth
  //offset.top = videoOffset.top
  //offset.left -= Math.round(videoWidth/4)
  
  //offset.left -= Math.round(videoWidth/2)
  //offset.left += Math.round(width/2)
  //offset.left = Math.max(0, offset.left)
  
  //$('video').offset(offset)
  
  //window.scroll($('video').offset().left - Math.round(videoWidth/2))
  //window.scroll(offset.left - Math.round($(window).width()/2) + Math.round(width/2))]
  $('html, body').stop(true, true)
  var oldOffset = $('html, body').scrollLeft()
  var newOffset = offset.top - 48 - videoHeight - (windowBottom - videoBottom)/2
  if (false) {
    $('html, body').scrollTop(newOffset)
    //gotoDialogInProgress = false
    setTimeout(function() {gotoDialogInProgress = false}, 50)
  } else if (Math.abs(newOffset - oldOffset) > $(window).width()) {
    //$('html, body').scrollTop(newOffset)
    $('html, body').animate({scrollTop: newOffset}, 30)
    setTimeout(function() {gotoDialogInProgress = false}, 130)
  } else {
    $('html, body').animate({scrollTop: newOffset}, 100)
    setTimeout(function() {gotoDialogInProgress = false}, 200)
  }
  // - Math.round($(window).width()/2 + width/2)
  
  

  //var oldOffset = $('html, body').scrollLeft()
  //var newOffset = offset.left - Math.round($(window).width()/2) + Math.round(width/2) + Math.round($('#dialogStartSpaceWS' + dialogNum).width()/2)
  //if (Math.abs(newOffset - oldOffset) > $(window).width()) {
  //  $('html, body').animate({scrollLeft: newOffset}, 100)
  //} else {
  //  $('html, body').animate({scrollLeft: newOffset}, 300)
  //}
  //$('body').animate({scrollLeft: Math.round($('#dialogStartSpaceWS' + dialogNum).scrollLeft())}, 10)

  

}

dialogsSetUp = {}

/*
function setupHoverForDialog(dialogNum) {
  if (dialogsSetUp[dialogNum]) return
  dialogsSetUp[dialogNum] = true
  var annotatedWordList = annotatedWordListListG[dialogNum][2]
  for (var i = 0; i < annotatedWordList.length; ++i) {
    var word = annotatedWordList[i][0]
    var pinyin = annotatedWordList[i][1]
    var english = annotatedWordList[i][2]
    //var randid = wordToId[word]
    var randid = 'wid_q_' + dialogNum + '_i_' + i
    setHoverTrans(randid, english)
    if (subLanguage == 'en') {
      //setClickPronounceEN(randid, word)
    } else if (subLanguage == 'zh') {
      //setClickPronounceZH(randid, pinyin)
    }
  }
}
*/

function translateButtonPressed(sentence, firstWordId) {
  if ($('#translation').attr('isFullTranslation') == 'true' && $('video')[0].paused) {
    $('video')[0].play();
  } else {
    $('video')[0].pause();
  }
  showFullTranslation(sentence, firstWordId)
}

function showFullTranslation(sentence, firstWordId) {
  console.log(sentence)
  clearHoverTrans()
  var currentTimeDeciSecs = Math.round($('video')[0].currentTime*10)
  now.getNativeSubAtTime(currentTimeDeciSecs, function(translation) {
    console.log(translation)
    $('#translation').text(translation)
    $('#translation').attr('isFullTranslation', 'true')
    placeTranslationText(firstWordId)
    var offset = $('#translation').offset()
    offset.left = $(window).width()/2 - $('#translation').width()/2
    $('#translation').offset(offset)
    $('#translation').show()
  })
  /*
  now.getTranslations(sentence, function(translation) {
    console.log(translation[0].TranslatedText)
    $('#translation').text(translation[0].TranslatedText)
    placeTranslationText(firstWordId)
    var offset = $('#translation').offset()
    offset.left = $(window).width()/2 - $('#translation').width()/2
    $('#translation').offset(offset)
    $('#translation').show()
  })
  */
}

function setNewSubtitles(annotatedWordList) {
  setNewSubtitleList([[0, 1, annotatedWordList]])
}

annotatedWordListListG = []

function setNewSubtitleList(annotatedWordListList) {
annotatedWordListListG = annotatedWordListList
//console.log(annotatedWordList.toString())
//if (annotatedWordList.length == 0) return
$('#translationTriangle').hide()
$('#translation').text('')
$('#translation').attr('isFullTranslation', 'false')
var nhtml = []

dialogStartTimesDeciSeconds = []

var wordToId = {}

//$('video').css('left', Math.round($(window).width()/2 - $('video')[0].videoWidth/2).toString())

//pinyinRow.push('<td style="display:-moz-inline-box;display:inline-block;width:' + ($('video').offset().left + Math.round($('video')[0].videoWidth/2))+ 'px;"></td>')
//wordRow.push('<td style="display:-moz-inline-box;display:inline-block;width:' + ($('video').offset().left + Math.round($('video')[0].videoWidth/2)) + 'px;"></td>')

for (var q = 0; q < annotatedWordListList.length; ++q) {
var startTimeDeciSeconds = annotatedWordListList[q][0]
dialogStartTimesDeciSeconds[q] = startTimeDeciSeconds
var startHMS = toHourMinSec(Math.round(startTimeDeciSeconds/10))
var annotatedWordList = annotatedWordListList[q][2]

nhtml.push('<table border="0" cellspacing="0">')

var pinyinRow = []
var wordRow = []
var whitespaceRow = []

//console.log(annotatedWordList)

//pinyinRow.push('<td id="dialogStartSpacePYS' + q + '" style="background-color: white; color: black; text-align: center; font-size: 18px" class="spacingPYS" onclick="gotoDialog(' + q + ')"></td>')
//wordRow.push('<td id="dialogStartSpaceWS' + q + '" style="background-color: white; color: black; text-align: center; font-size: 32px" class="spacingWS" onclick="gotoDialog(' + q + ')">　</td>')

var allWords = []
for (var i = 0; i < annotatedWordList.length; ++i) {
  allWords.push(annotatedWordList[i][0])
}
var currentSentence = escapeHtmlQuotes(allWords.join(''))

var firstWordId = ''

for (var i = 0; i < annotatedWordList.length; ++i) {
var word = annotatedWordList[i][0]
var pinyin = annotatedWordList[i][1]
var english = annotatedWordList[i][2]
if (english == null) english = ''
else english = escapeHtmlQuotes(english)

if (wordToId[word] == null)
  wordToId[word] = Math.round(Math.random() * 1000000)
//var randid = wordToId[word]
var randid = 'wid_q_' + q + '_i_' + i
if (i == 0) firstWordId = randid;

coloredSpans = []
pinyinWords = pinyin.split(' ')

for (var j = 0; j < pinyinWords.length; ++j) {
  var curWord = pinyinWords[j]
  var tonecolor = ['red', '#AE5100', 'green', 'blue', 'black'][getToneNumber(curWord)-1]
  coloredSpans.push('<span style="color: ' + tonecolor + '">' + curWord + '</span>')
}
var pinyinspan = '<td nowrap="nowrap" style="text-align: center;" class="' + randid + ' hoverable pinyinspan pys' + q + '" onclick="wordClicked(' + q + ')">' + coloredSpans.join(' ') + '</td>'
var wordspan = '<td nowrap="nowrap" dialognum=' + q + ' style="text-align: center;" hovertext="' + english + '" id="WS' + randid + '" class="' + randid + ' hoverable wordspan ws' + q + '" onmouseover="onWordHover(\'' + randid + '\')" onmouseout="onWordLeave(\'' + randid + '\')" onclick="wordClicked(' + q + ')">' + word + '</td>'
if (word == ' ') {
  wordspan = '<td style="font-size: xx-small">　</td>'
}

pinyinRow.push(pinyinspan)
wordRow.push(wordspan)
whitespaceRow.push('<td id="whitespaceS' + q + '" style="font-size: 32px">　</td>')

}

wordRow.push('<td id="translate"' + q + '" style="font-size: 32px">　</td>')
wordRow.push('<td id="translate"' + q + '" style="font-size: 32px; display: none; white-space: nowrap" class="translateButton tb' + q + '" onclick="translateButtonPressed(\'' + currentSentence + '\', \'' + firstWordId + '\')">翻译</td>')

//pinyinRow.push('<td id="dialogEndSpacePYS' + q + '" style="background-color: white; color: black; text-align: center; font-size: 18px" class="spacingPYS" onclick="gotoDialog(' + q + ')"></td>')
//wordRow.push('<td id="dialogEndSpaceWS' + q + '" style="background-color: white; color: black; text-align: center; font-size: 32px" class="spacingWS" onclick="gotoDialog(' + q + ')">　</td>')

nhtml.push('<col>' + pinyinRow.join('') + '</col>')
nhtml.push('<col>' + wordRow.join('') + '</col>')
nhtml.push('<col>' + whitespaceRow.join('') + '</col>')

nhtml.push('</table>')

}

$('#caption').html(nhtml.join(''))

/*
for (var q = 0; q < annotatedWordListList.length; ++q) {
var annotatedWordList = annotatedWordListList[q][2]
for (var i = 0; i < annotatedWordList.length; ++i) {
  var word = annotatedWordList[i][0]
  var pinyin = annotatedWordList[i][1]
  var english = annotatedWordList[i][2]
  //var randid = wordToId[word]
  var randid = 'wid_q_' + q + '_i_' + i
  //setHoverTrans(randid, english)
  if (subLanguage == 'en') {
    setClickPronounceEN(randid, word)
  } else if (subLanguage == 'zh') {
    //setClickPronounceZH(randid, pinyin)
  }
}
}
*/

gotoDialogNoVidSeek(0)
//$('video')[0].play()
}

function videoLoaded() {
  var videoWidth = $('video')[0].videoWidth
  $('video').css('left', '50%')
  $('video').css('margin-left', -Math.round(videoWidth/2))
  $('#videoSpacing').css('margin-top', ($('video').offset().top + $('video')[0].videoHeight))
  //var videoOffset = $('video').offset()
  //videoOffset.left = Math.round($(window).width()/2 - $('video')[0].videoWidth/2)
  //$('video').offset(videoOffset)
}

function onTimeChanged(s) {
  var targetTimeDeciSecs = Math.round(s.currentTime*10)
  var lidx = 0
  var ridx = dialogStartTimesDeciSeconds.length-1
  while (lidx < ridx+1) {
    var midx = Math.floor((lidx + ridx)/2)
    var ctime = dialogStartTimesDeciSeconds[midx]
    if (ctime > targetTimeDeciSecs)
      ridx = midx - 1
    else
      lidx = midx + 1
  }
  if (ridx < 0) ridx = 0
  gotoDialogNoVidSeek(ridx)
//now.getAnnotatedSubAtTime(Math.round(s.currentTime*10), setNewSubtitles)
//now.getSubPixAtTime(Math.round(s.currentTime*10), setNewSubPix)
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
//$('#playPauseButton').text('Pause (Space)')
//$('#prevLineButton').show()
//$('#nextLineButton').show()
//$('video').width($('video')[0].videoWidth)
//$('video').height($('video')[0].videoHeight)
}

function videoPaused() {
//$('#playPauseButton').text('Play (Space)')
//$('#prevLineButton').show()
//$('#nextLineButton').show()
}

/*
function videoClicked() {
  var vid = $('video')[0]
  if (vid.paused)
    vid.play()
  else
    vid.pause()
}
*/

$(document).click(function(x) {
var vid = $('video')[0]
var videoLeft = $('video').offset().left
var videoTop = $('video').offset().top
var videoWidth = $('video')[0].videoWidth
var videoHeight = $('video')[0].videoHeight
if (x.pageX < videoLeft || x.pageX > videoLeft + videoWidth) return true
if (x.pageY < videoTop || x.pageY > videoTop + videoHeight - 40) return true
//var mouseCoords = relMouseCoords(x, vid)
//if (mouseCoords.y > $('video')[0].videoHeight - 30 || mouseCoords.x > $('video')[0].videoWidth) return true
if (vid.paused)
  vid.play()
else
  vid.pause()
return false
})

/*
$(document).click(function(x) {
var vid = $('video')[0]
var mouseCoords = relMouseCoords(x, vid)
if (mouseCoords.y > $('video')[0].videoHeight - 30 || mouseCoords.x > $('video')[0].videoWidth) return true
if (vid.paused)
  vid.play()
else
  vid.pause()
return false
})
*/

function checkKey(x) {
  var vid = $('video')[0]
  console.log(x.keyCode)
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
  } else if (x.keyCode == 38) { // up arrow
    prevButtonPressed()
    x.preventDefault()
  } else if (x.keyCode == 40) { // down arrow
    nextButtonPressed()
    x.preventDefault()
  }
}

$(document).keydown(checkKey)

function mouseWheelMove(event, delta) {
  if (delta > 0) {
    gotoDialog(prevDialogNum - 1)
  } else {
    gotoDialog(prevDialogNum + 1)
  }
}

//pausedFromLeftButtonHold = false

function mouseDown(event) {
  if (event.which == 2) { // middle button
    flipPause()
    event.preventDefault()
  }
  if (event.which == 3) { // right button
    flipPause()
    event.preventDefault()
  }
  /*
  if (event.which == 1 && !$('video')[0].paused) { // left button
    $('video')[0].pause()
    pausedFromLeftButtonHold = true
    $('body').addClass('unselectable')
    //$('video').trigger(event)
    //event.preventDefault()
    //event.stopImmediatePropagation()
    //event.stopPropagation()
  }
  */
}

$(document).mousedown(mouseDown)
/*
function mouseUp(event) {
  if (event.which == 1 && pausedFromLeftButtonHold) { // left button, resume
    pausedFromLeftButtonHold = false
    $('body').removeClass('unselectable')
    $('video')[0].play()
  }
}

$(document).mouseup(mouseUp)
*/

$(document).mousewheel(mouseWheelMove)

function onScroll() {
  //$('video')[0].pause()
  if (gotoDialogInProgress) return
  $.doTimeout('scroll', 300, function() {
    var videoHeight = $('video')[0].videoHeight
    var videoBottom = $('video').offset().top + videoHeight
    var windowBottom = $('#bottomOfScreen').offset().top
    var windowTop = $(window).scrollTop()
    var center = (windowBottom + videoBottom) / 2
    //console.log(center)
    //console.log($.nearest({x: $(window).width()/2, y: center}, '.wordspan')[0])
    dialognum = $($.nearest({x: $(window).width()/2, y: center}, '.wordspan')[0]).attr('dialognum')
    console.log(dialognum)
    gotoDialog(dialognum, true)
  })
}

$(document).scroll(onScroll)

$(document)[0].addEventListener('contextmenu', function(event) {
  event.preventDefault()
})

$(window).bind('hashchange',function(event){
    var anchorhash = location.hash.replace('#', '');
    if (anchorhash == '')
      return
    if (gotoDialogInProgress)
      return
    gotoDialog(parseInt(anchorhash))
});

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
    //now.initializeSubtitle(subtitleText, subLanguage)
    now.initializeSubtitle(subtitleText, subLanguage, targetLanguage, function() {
      now.getFullAnnotatedSub(setNewSubtitleList)
    })
  } else { // this is the subtitle text
    //now.initializeSubtitleText(subtitleText, subLanguage)
    now.initializeSubtitleText(subtitleText, subLanguage, targetLanguage, function() {
      now.getFullAnnotatedSub(setNewSubtitleList)
    })
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
