root = exports ? this
print = console.log

redis = require 'redis'
client = redis.createClient()

sys = require 'util'
child_process = require 'child_process'

pinyinutils = require './static/pinyinutils'

fs = require 'fs'

dictText = fs.readFileSync('static/cedict_full.txt', 'utf8')
chinesedict = require './static/chinesedict'
cdict = new chinesedict.ChineseDict(dictText)

deferred = require 'deferred'

$ = require 'jQuery'

extended_vocab = {
  '千雪峰': {
    pinyin: 'Qian1Xue3Feng1',
    english: 'Snow-Capped Mountain',
  },
  '开花': {
    english: 'bloom',
  },
  '皇上': {
    english: 'emperor',
  },
  '当今皇上': {
    multi: [['当今', 'dang1jin1', 'current'], ['皇上', 'huang2shang4', 'emperor']],
  },
  '老前辈': {
    english: 'old senior',
  },
  '卓老前辈': {
    multi: [['卓', 'Zhuo1', 'Zhuo'], ['老前辈', 'lao3qian2bei4', 'old senior']]
    english: 'old senior',
  },
  '白发': {
    pinyin: 'bai2fa1',
    english: 'white hair',
  },
  '给你们': {
    multi: [['给', 'gei3', 'give'], ['你们', 'ni3men', 'you']]
  },
  '出剑': {
    english: 'to draw a sword'
  }
  '凝': {
    english: 'to concentrate',
  },
  '练熟': {
    multi: [['练', 'lian4', 'to practice'], ['熟', 'shou2', 'skilled']]
  },
  '给你': {
    multi: [['给', 'gei3', 'give'], ['你', 'ni3', 'you']]
  },
  '亏待': {
    english: 'treat unfairly',
  },
  '一航': {
    pinyin: 'Yi1Hang2',
    english: 'Yi Hang',
  },
  '卓一航': {
    pinyin: 'Zhuo1Yi1Hang2',
    english: 'Zhuo Yi Hang',
  },
  '一次': {
    english: 'once',
  },
  '决定': {
    english: 'decide',
  },
  '朝庭': {
    english: 'Royal Court',
  },
  '大清朝廷': {
    english: 'Qing Royal Court',
  },
  '龙体欠安': {
    multi: [['龙体', 'Long2Ti3', 'Long Ti'], ['欠安', 'qian4an1', 'ill']]
  },
  '中原': {
    english: 'Zhong Yuan',
    pinyin: 'Zhong1Yuan2',
  },
  '八大派': {
    english: 'Eight Big Clans',
  },
  '八大门派': {
    english: 'Eight Big Clans',
  },
  '武当派': {
    english: 'Wu Dang Clan'
  },
  '口中': {
    multi: [['口', 'kou3', 'mouth'], ['中', 'zhong1', 'inside']]
  },
  '正与邪': {
    multi: [['正', 'zheng4', 'good'], ['与', 'yu3', 'and'], ['邪', 'xie2', 'evil']]
  },
  '正邪': {
    english: 'good and evil'
  },
  '盟主': {
    english: 'Joint Chief'
  },
  '邪派': {
    multi: [['邪', 'xie2', 'evil'], ['派', 'pai4', 'clan']]
  },
  '还有': {
    english: 'still have',
  },
  '除了': {
    english: 'apart from'
  },
  '八旗': {
    pinyin: 'Ba1Qi2'
    english: 'Eight Banners (military organization)',
  },
  '采得': {
    english: 'collected',
  },
  '总管': {
    english: 'Chief',
  },
  '耶律聂堂': {
    pinyin: 'Ye1Lv4Nie4Tang2',
    english: 'Ye Lu Nie Tang',
  },
  '一个都不留': {
    multi: [['一个', 'yi1ge', 'one'], ['都', 'dou1', 'all'], ['不', 'bu4', 'not'], ['留', 'liu2', 'remain']]
  },
  '挺住': {
    english: 'stand firm',
  },
  '阿弥陀佛': {
    english: 'Amitabha Buddha',
  },
  '挨个人': {
    multi: [['挨个', 'ai2ge4', 'one by one'], ['人', 'ren2', 'person']],
  },
  '班长': {
    english: 'Class President',
  },
  '丫头': {
    english: 'girl',
  },
  '吗': {
    english: '(question tag)',
  },
  '银别': {
    english: 'Yin Bie (name)',
    pinyin: 'Yin2 Bie2',
  },
  '有没有': {
    english: 'do you have?',
  },
  '蜘顺': {
    english: "Zhi Shun (spider's name)",
  },
  '高中毕业证': {
    multi: [['高中', 'gao1 zhong1', 'high school'], ['毕业', 'bi4 ye4', 'graduation'], ['证', 'zheng4', 'certificate']],
  },
  '多星星': {
    multi: [['多', 'duo1', 'many'], ['星星', 'xing1xing1', 'stars']]
  },
  '汗江': {
    english: 'Han River',
  },
  '大不了': {
    english: 'serious',
  },
  '一只': {
    english: 'one (small animal)',
  },
  '两只': {
    english: 'two (small animals)',
  },
  '三只': {
    english: 'three (small animals)',
  },
  '10只': {
    english: 'ten (small animals)',
  },
  '没关系': {
    english: "it doesn't matter",
    pinyin: 'mei2guan1xi4',
  },
  '武当': {
    english: 'WuDang',
    pinyin: 'Wu3 Dang1',
  },
  '铲平': {
    english: '',
  },
}

context_vocab = {
'施祖皇帝突患重病': {
  '突': {
    english: 'suddenly',
    pinyin: 'tu1',
  },
},
'八点四十分': {
  '八点': {
    english: "eight o'clock",
    pinyin: 'ba1dian3',
  },
  '四十分': {
    english: "fourty minutes",
    pinyin: 'si4shi2fen1',
  },
},
'听闻卓老前辈所守护的奇花': {
  '听闻': {
    english: 'to hear',
  },
  '守护': {
    english: 'to guard',
  },
},
'剑气护体，花落不沾身！': {
  '沾': {
    english: 'to touch',
  },
}
'我没有资格当老师': {
  '当': {
    english: 'to act as',
  },
}
'还有你我才觉得有活的滋味啊': {
  '滋味': {
    english: 'feeling',
  },
},
'不是说敲一下门吗': {
  '门吗': {
    multi: [['门', 'men2', 'door'], ['吗', 'ma', '(question tag)']],
  },
},
'卓一航，你听到我们统领说的话没有': {
  '统领': {
    english: 'commander',
  },
},
'到底有没有良心': {
  '到底': {
    english: 'in the end',
  },
},
'如果不是一时间就能学会我干嘛要请你这么贵的老师': {
  '干嘛': {
    english: 'why on earth?',
  },
},
'蜘顺！蜘顺！我在找你呢,快点出来': {
  '你呢': {
    multi: [['你', 'ni3', 'you'], ['呢', 'ne', 'currently']]
  },
  '在': {
    english: 'in the middle of doing sth',
  },
},
'已经都几回了': {
  '回了': {
    multi: [['回', 'hui2', 'times'], ['了', 'le', '']]
  },
  '几': {
    english: 'how many',
  },
},
'我对爸爸自豪呢': {
  '对': {
    english: 'towards'
  },
},
'难道只对金钱和势力活着的那样的老师会有尊敬感吗': {
  '势力活着': {
    multi: [['势力', 'shi4 li', 'power'], ['活着', 'huo2 zhe', 'living']],
  },
},
'是啊！如果有能打我的老师我就当他的学生': {
  '当': {
    english: 'to act as'
  },
},
'吃了豹子胆敢对我的女儿动手': {
  '豹子胆敢': {
    multi: [['豹子', 'bao4 zi', 'leopard'], ['胆敢', 'dan3 gan3', 'to dare']]
  },
  '动手': {
    english: 'to hit',
  },
},
'溺爱子女是错误': {
  '溺爱子女': {
    multi: [['溺爱', 'ni4 ai4', 'to spoil'], ['子女', 'zi4 nv4', 'children']]
  },
  '错误': {
    english: 'mistake',
  },
},
'老师连老师的爷爷都不能打': {
  '连老师': {
    multi: [['连', 'lian2', 'even'], ['老师', 'lao3 shi1', 'teacher']]
  },
},
'从今天开始禁止出入知道了吗': {
  '禁止': {
    english: 'to prohibit',
  },
  '出入': {
    english: 'to go out and come in',
  },
},
'应该是禁止外出吧' : {
  '禁止': {
    english: 'to prohibit',
  },
},
'连画一个星星也是用各种颜色吧': {
  '连画': {
    multi: [['连', 'lian2', 'even'], ['画', 'hua4', 'to paint']],
  },
},
'是会长': {
  '是': {
    english: 'yes',
  },
},
'我不管别人怎么说': {
  '不管': {
    english: 'regardless of',
  },
},
}

addContextVocab = (chinese, vocabdict) ->
  context_vocab[chinese] = $.extend(context_vocab[chinese], vocabdict)

for x in ['传说千雪峰有一朵奇花', '朝庭决定派遣使者到雪山寻花', '听闻卓老前辈所守护的奇花', '前辈，只要奇花能医好皇上的龙体', '这一朵花不是给你们的', '剑气护体，花落不沾身！']
  addContextVocab x, {
    '花': {
      english: 'flower'
    }
  }

uniquify = (list) ->
  output = []
  seen = {}
  for x in list
    if not seen[x]?
      seen[x] = true
      output.push x
  return output

removeEmpty = (list) ->
  output = []
  for x in list
    if x != ''
      output.push x
  return output

parseAdsoOutput = (stdout) ->
  if stdout.trim() == ''
    return []
  cnwords = []
  pywords = []
  lines = stdout.split('\n')
  for line in lines
    [word, pinyin, english, pos] = line.split('\t')
    cnwords.push(word)
    pywords.push(pinyin)
  chinese = cnwords.join('')
  words = []
  skipwords = 0
  for line,idx in lines
    if skipwords > 0
      skipwords -= 1
      continue
    [word, pinyin, english, pos] = line.split('\t')
    nextword = cnwords[idx+1]
    next2word = cnwords[idx+2]
    nextword_py = pywords[idx+1]
    next2word_py = pywords[idx+2]
    customwinf = false
    for exvocab in [context_vocab[chinese], extended_vocab]
      if not exvocab?
        continue
      innerbreak = false
      for [nword,npinyin],idx in [[word+nextword+next2word, pinyin+nextword_py+next2word_py], [word+nextword, pinyin+nextword_py], [word, pinyin]]
        if exvocab[nword]?
          innerbreak = true
          skipwords += 2-idx
          wordinfo = exvocab[nword]
          if wordinfo['multi']?
            winf = wordinfo['multi']
            customwinf = true
            break
          word = nword
          if wordinfo['pinyin']?
            pinyin = wordinfo['pinyin']
          else
            pinyin = npinyin
          english = wordinfo['english']
          break
      if innerbreak
        break
    if not customwinf
      if pinyin?
        pinyin = pinyinutils.toneNumberToMark(pinyin)
      winf = [[word, pinyin, english]]
    else
      winf = ([word, pinyinutils.toneNumberToMark(pinyin), english] for [word, pinyin, english] in winf)
    for x in winf
      words.push(x)
  #return words
  #words = ([word,pinyin,(removeEmpty uniquify([english.trim()].concat(cdict.getEnglishListForWord(word)))).join('/')] for [word,pinyin,english] in words)
  #return words
  output = []
  for [word,pinyin,english] in words
    if (not pinyin?) or (not english?) or (not hasAlpha(pinyin)) or (english.trim().length == 0)
      pinyin = cdict.getPinyinForWord(word)
      english = (removeEmpty uniquify(cdict.getEnglishListForWord(word))).join('/')
    else
      english = (removeEmpty uniquify([english.trim()].concat(cdict.getEnglishListForWord(word)))).join('/')
    output.push [word,pinyin,english]
  return output

hasAlpha = (text) ->
  isAlpha = (c) ->
    'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'.indexOf(c) != -1
  return (1 for c in text when isAlpha(c)).length > 0

escapeshell = (cmd) ->
  return "'" + cmd.split("'").join("\'").split('\n').join(' ') + "'"
  #return '"'+cmd.replace(/(["\s'$`\\])/g,'\\$1')+'"'

getWordsPinyinEnglishCached = (text, callback) ->
  client.get('adsovocab|' + text, (err, reply) ->
    if reply? and reply.indexOf('connect to MySQL') == -1
      output = parseAdsoOutput(reply)
      if output? and (x[0] for x in output).join('').trim().length > 0
        callback(output)
        return
    command = "./adso --vocab -i " + escapeshell(text)
    child_process.exec(command, (error, stdout, stderr) ->
      stdout = stdout.trim()
      client.set('adsovocab|' + text, stdout)
      callback(parseAdsoOutput(stdout))
    )
  )

englishStopwordsList = ['i', 'me', 'my', 'myself', 'we', 'our', 'ours', 'ourselves', 'you', 'your', 'yours', 'yourself', 'yourselves', 'he', 'him', 'his', 'himself', 'she', 'her', 'hers', 'herself', 'it', 'its', 'itself', 'they', 'them', 'their', 'theirs', 'themselves', 'what', 'which', 'who', 'whom', 'this', 'that', 'these', 'those', 'am', 'is', 'are', 'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had', 'having', 'do', 'does', 'did', 'doing', 'a', 'an', 'the', 'and', 'but', 'if', 'or', 'because', 'as', 'until', 'while', 'of', 'at', 'by', 'for', 'with', 'about', 'against', 'between', 'into', 'through', 'during', 'before', 'after', 'above', 'below', 'to', 'from', 'up', 'down', 'in', 'out', 'on', 'off', 'over', 'under', 'again', 'further', 'then', 'once', 'here', 'there', 'when', 'where', 'why', 'how', 'all', 'any', 'both', 'each', 'few', 'more', 'most', 'other', 'some', 'such', 'no', 'nor', 'not', 'only', 'own', 'same', 'so', 'than', 'too', 'very', 's', 't', 'can', 'will', 'just', 'don', 'should', 'now']

englishStopwords = {}
for x in englishStopwordsList
  englishStopwords[x] = true

overlapPercentage = root.overlapPercentage = (words1, words2) ->
  console.log words1
  console.log words2
  overlapNum = 0
  for key,value of words1
    if words2[key]?
      overlapNum += 1
  console.log overlapNum / Math.min(words1.length, words2.length)
  return overlapNum / Math.min(words1.length, words2.length)

listEnglishWordsInSentence = root.listEnglishWordsInSentence = (text) ->
  englishWords = {}
  for x in text.split(/[^A-Za-z0-9]+/)
    x = x.toLowerCase()
    if x.length > 0 and (not englishWords[x]?) and (not englishStopwords[x]?)
      englishWords[x] = true
  return englishWords

sentenceOverlapPercentageWithWords = root.sentenceOverlapPercentageWithWords = (sentence, words) ->
  return overlapPercentage(listEnglishWordsInSentence(sentence), words)

root.getEnglishWordsInGloss = (text, callback) ->
  await
    getWordsPinyinEnglishCached(text, defer(wordsPinyinEnglish))
  englishWords = {}
  for [word, pinyin, english] in wordsPinyinEnglish
    for x in english.split(/[^A-Za-z0-9]+/)
      x = x.toLowerCase()
      if x.length > 0 and (not englishWords[x]?) and (not englishStopwords[x]?)
        englishWords[x] = true
  callback englishWords


root.getWordsPinyinEnglishCached = getWordsPinyinEnglishCached

main = ->
  text = process.argv[2] ? '中华人民共和国'
  print text
  getWordsPinyinEnglishCached(text, (words) ->
    for [word,pinyin,english] in words
      console.log word
      console.log pinyin
      console.log english
  )

main() if require.main is module
