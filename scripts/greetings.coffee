# Description:
#   hubot scripts to greet members friendly
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   None
#
# Author:
#   kechol

module.exports = (robot) ->

  hellos = [
    '(=ﾟωﾟ)ﾉぃょぅ'
    ,'チョインす！'
    ,'こんにちは！'
    ,'|^・ω・)/ ﾊﾛｰ♪'
  ]

  byes = [
    'ヽ( ´ー`)ノ　まったね～'
    ,'バイバイ'
  ]

  thanks = [
    'あ(￣○￣)り(￣◇￣)が(￣△￣)と(￣0￣)う(￣ー￣)'
    ,'アリガト━((*´д`爻´д`*))━!!!!'
  ]

  busys = [
    'おつであります♪　(ｃ_･`｡)ﾍﾍ(･ω･`｡)ﾓﾐﾓﾐ'
    ,'ォッヵレサ―ヾ(★´∀`☆)ノ―ﾝｯｯ♪'
  ]

  congrats = [
    'ｲｲﾈ(ﾟ∀ﾟ≡ｲｲﾈ(ﾟ∀ﾟ≡ﾟ∀ﾟ)ｲｲﾈ≡ﾟ∀ﾟ)超ｲｲﾈｰ!!'
    ,'ワッショイヽ(゜∀゜)メ(゜∀゜)メ(゜∀゜)ノワッショイ'
    ,'ｵﾒﾃﾞﾄｺｰﾗｽ ｻﾝ!ﾊｲ! /･ω･)/~~(´∀`*)(´∀`*)(´∀`*)ｵ～ﾒ～'
  ]

  answers = [
    '((ﾉ(_ _ ﾉ)ﾖﾛｼｸｵﾈｶﾞｲｼﾏｽ'
    ,'夜露死苦(ｷ￣Д￣)y─┛~~~'
    ,'(ﾟﾛﾟ)ﾑﾘ(ﾟﾛﾟ)ﾑﾘ(ﾟﾛﾟ)ﾑﾘ(ﾟﾛﾟ)ﾑﾘ(ﾟﾛﾟ)ﾑﾘ(ﾟﾛﾟ)ﾑﾘ(ﾟﾛﾟ)ﾑﾘ(ﾟﾛﾟ)ﾑﾘ'
    ,'OK━承諾━許可━採用━ヽ(　*ﾟДﾟ)ﾉ━採用━許可━承諾━OK♪'
    ,'（≧▽≦）ゝ了解シマシタ!!'
  ]

  sorrys = [
    'すいませんでした　ﾍﾟｺﾘ(o_ _)ｏ))'
    ,'(*_ _)人ゴメンナサイ'
  ]

  cheers = [
    '＼(*゜ロ＼)*゜ロ＼)*゜ロ＼)ど...ど...ど...どんまい! '
    ,'ｽﾄﾚｽﾀﾒﾙﾄ（*´し`）／（・・；）ﾊｹﾞﾙﾖ '
  ]

  mornings = [
    'Oo(っд･`｡)ｵﾊﾖｫ…'
    ,'(。・∀・)ノ゛おっは～'
  ]

  nights = [
    'ヾ(*￣￣￣￣▽￣￣￣￣*)ノこんばんわ♪'
    ,'こんばんわ━( ・∀・)ノ□☆□ヽ(・∀・ )━ｯ!'
    ,'ｵﾊﾖｳｶ!?>Σ(ﾟДﾟ;≡;ﾟдﾟ) <ｲﾔｺﾝﾊﾞﾝﾜ!！'
  ]

  robot.hear /こんにち(は|わ)/, (msg) ->
    msg.send msg.random hellos

  robot.enter (msg) ->
    msg.send msg.random hellos

  robot.hear /(ばいば(ー|〜)*い|さよう?なら)/, (msg) ->
    msg.send msg.random byes

  robot.leave (msg) ->
    msg.send msg.random byes

  robot.hear /ありがと(う|ー|〜|っ|！)+/, (msg) ->
    msg.send msg.random thanks

  robot.hear /(了解|承知|わかり)(いた|致)?し?(ました|です)/, (msg) ->
    msg.send msg.random thanks

  robot.hear /お(つか|疲)れ/, (msg) ->
    msg.send msg.random busys

  robot.hear /(終わり|完了し|終了し|リリースし|でき|ておき)ました/, (msg) ->
    msg.send msg.random congrats

  robot.hear /【祝】/, (msg) ->
    msg.send msg.random congrats

  robot.respond /祝って/, (msg) ->
    msg.send msg.random congrats

  robot.hear /((よろ|宜)しく)?お?(願|ねが)い((致|いた)?します|できますか)/, (msg) ->
    msg.send msg.random answers

  robot.hear /(ごめん|すみません|申し訳|もうしわけ|失礼(致|いた)?しました)/, (msg) ->
    msg.send msg.random cheers

  robot.hear /(疲|つか)れた/, (msg) ->
    msg.send msg.random cheers

  robot.hear /(辛|つら)い/, (msg) ->
    msg.send msg.random cheers

  robot.respond /(こら|ふざけ(ん|る)な|謝(れ|りなさい))$/, (msg) ->
    msg.send msg.random sorrys

  robot.hear /こんばん(は|わ)/, (msg) ->
    msg.send msg.random nights

  robot.hear /おはよ(う|ー|〜|っ|！)+/, (msg) ->
    msg.send msg.random mornings
