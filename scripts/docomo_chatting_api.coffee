# Description:
#   DOCOMOの自然対話APIを利用した雑談
#

###
getTimeDiffAsMinutes = (old_msec) ->
  now = new Date()
  old = new Date(old_msec)
  diff_msec = now.getTime() - old.getTime()
  diff_minutes = parseInt( diff_msec / (60*1000), 10 )
  return diff_minutes
###

module.exports = (robot) ->
  status = {}
  robot.respond /(\S+)/i, (msg) ->
    message = msg.match[1]
    HUBOT_DOCOMO_DIALOGUE_API_KEY = process.env.HUBOT_DOCOMO_DIALOGUE_API_KEY
    HUBOT_DOCOMO_DIALOGUE_APPID   = process.env.HUBOT_DOCOMO_DIALOGUE_APPID

    ## 前回会話した時間を取得
    KEY_DOCOMO_CONTEXT_TTL = 'docomo-talk-context-ttl'
    old_msec = robot.brain.get KEY_DOCOMO_CONTEXT_TTL
#    diff_minutes = getTimeDiffAsMinutes old_msec

    url = 'https://api.apigw.smt.docomo.ne.jp/naturalChatting/v1/dialogue?APIKEY='+HUBOT_DOCOMO_DIALOGUE_API_KEY
    user_name = msg.message.user.name
    headers = {'Content-Type':'application/json'}

    d = new Date()
    appSendTime = d.getFullYear() + '-' + ('0' + (d.getMonth() + 1)).slice(-2) + '-' + ('0' + d.getDate()).slice(-2) + ' '\
                   + d.getHours() + ':' + d.getMinutes() + ':' + d.getSeconds()


    consol.log old_msec
    consol.log user_name

    request = require("request")
    request.post
      url: url
      headers: headers
      json:
        language: "ja-JP"
        botId: "Chatting"
        appId: HUBOT_DOCOMO_DIALOGUE_APPID
        voiceText: message
        clientData: {
          option: {
            nickname: user_name
            place: "東京"
            mode: "dialog"
            t: "kansai"
          }
        }
        appRecvTime: old_msec
        appSendTime: appSendTime
      , (err, response, body) ->

        ## 会話発生時間の保存
        robot.brain.set KEY_DOCOMO_CONTEXT_TTL, body.serverSendTime

        msg.send body.systemText.expression
