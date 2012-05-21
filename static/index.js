sub = {}

function onTimeChanged(s) {
//console.log(s.currentTime)
var currentTime = s.currentTime
var curSub = sub.subtitleAtTime(Math.round(currentTime))
if (curSub != '')
  $('#caption').text(curSub)
}

now.ready(function() {

now.getSubText(function(subText) {
sub = new SubtitleRead(subText)
console.log(subText)
})

})

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

$('body').mousemove(function(x) {
var vid = $('video')[0]
var mouseCoords = relMouseCoords(x, vid)
if (mouseCoords.y < $('video').height() && mouseCoords.x < $('video').width()) return
vid.pause()
console.log(mouseCoords.x + ',' + mouseCoords.y)
})

$('body').click(function(x) {
var vid = $('video')[0]
if (vid.paused)
  vid.play()
else
  vid.pause()
})

$('body').keypress(function(x) {
console.log(x)
if (x.keyCode != 32) return // not space
var vid = $('video')[0]
if (vid.paused)
  vid.play()
else
  vid.pause()
})
