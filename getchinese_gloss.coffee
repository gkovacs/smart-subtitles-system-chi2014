root = exports ? this
print = console.log

redis = require 'redis'
client = redis.createClient()

sys = require 'util'
child_process = require 'child_process'

pinyinutils = require './static/pinyinutils'

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
    multi: [['给', 'gei3', 'give'], ['你', 'ni3men', 'you']]
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
    english: 'stand firm'
  },
  '阿弥陀佛': {
    english: 'Amitabha Buddha',
  },
}

context_vocab = {
'施祖皇帝突患重病': {
  '突': {
    english: 'suddenly',
    pinyin: 'tu1',
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
}

addContextVocab = (chinese, vocabdict) ->
  context_vocab[chinese] = $.extend(context_vocab[chinese], vocabdict)

for x in ['传说千雪峰有一朵奇花', '朝庭决定派遣使者到雪山寻花', '听闻卓老前辈所守护的奇花', '前辈，只要奇花能医好皇上的龙体', '这一朵花不是给你们的', '剑气护体，花落不沾身！']
  addContextVocab x, {
    '花': {
      english: 'flower'
    }
  }

parseAdsoOutput = (stdout) ->
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
  return words

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

root.getWordsPinyinEnglishCached = getWordsPinyinEnglishCached

main = ->
  text = process.argv[2]
  print text
  getWordsPinyinEnglishCached(text, (words) ->
    for [word,pinyin,english] in words
      console.log word
      console.log pinyin
      console.log english
  )

main() if require.main is module
