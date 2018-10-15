# Description:
#   Searches restaurants from Hotpepper.
#
# Commands:
#   hubot ご飯 <query> - ご飯検索
#   hubot ランチ <query> - ランチ検索
#
# Author:
#   hnarita

RWS_API_KEY = process.env.HUBOT_RWS_API_KEY

cron = require("cron").CronJob
request = require("request")

module.exports = (robot) ->

  robot.respond /(hotpepper|gourmet|ご飯)( me)? (.*)/i, (msg) ->
    search_hpr msg.match[3], {},(err,res,msg_data) ->
      if msg_data?
        msg.send msg_data
      else
        msg.send "希望の店は見つからないね。何事も妥協が大事だよ。"

  robot.respond /(lunch|ランチ)( me)? (.*)/i, (msg) ->
    search_hpr msg.match[3], { lunch: 1 },(err,res,msg_data) ->
      if msg_data?
        msg.send msg_data
      else
        msg.send "希望の店は見つからないね。何事も妥協が大事だよ。"

  robot.respond /hpr$/, (msg) ->
    search_option =
      lunch: 1
      lat: 35.7277907
      lng: 139.7735347
      range: 3
      order: 4

    search_hpr "ランチ", search_option,(err,res,msg_data) ->
      msg_data.text = "もうすぐ昼だよ！今日のランチはどこにする？"
      msg.send msg_data

  cronjob = new cron(
    cronTime: "0 30 11 * * 1-6"    # 実行時間：秒・分・時間・日・月・曜日
    start:    true                # すぐにcronのjobを実行するか
    timeZone: "Asia/Tokyo"        # タイムゾーン指定
    onTick: ->                    # 時間が来た時に実行する処理
      search_option =
        lunch: 1
        lat: 35.7277907
        lng: 139.7735347
        range: 3
        order: 4

      search_hpr "ランチ", search_option,(err,res,msg_data) ->
        msg_data.text = "もうすぐ昼だよ！今日のランチはどこにする？"
        robot.messageRoom "talk", msg_data
  )

# リクルートWEB サービス：グルメサーチAPI から情報を取得
search_hpr = (keyword, conditions,callback)->
  apiUrl="http://webservice.recruit.co.jp/hotpepper/gourmet/v1/"
  qs = conditions
  qs.key = RWS_API_KEY
  qs.keyword = keyword
  qs.count = 50
  qs.format = 'json'

  options =
    url: apiUrl
    qs: qs

  request.get options, (err,res,body) ->
    if err? or isnt 200
      console.log err
    else
      if JSON.parse(body).results. results_returned == 0
        msg_data = {}
      else
        shops = JSON.parse(body).results.shop
        shuffle shops
        attachments = []
        for shop in shops[0..3]
          attachments.push(
            color: "#ff420b"
            title: "#{shop.name}"
            title_link: "#{shop.urls.pc}"
            text: "#{shop.catch}"
            footer: ":access_gray: #{shop.access}\n:yen_gray: #{shop.budget.average}\n:time_gray: #{shop.open}"
            image_url: "#{shop.photo.pc.m}#.png"
          )
        msg_data =
          attachments: attachments

      callback(err,res,msg_data)


# arrayをシャッフルする関数
shuffle = (array) ->
  i = array.length
  if i is 0 then return false
  while --i
    j = Math.floor Math.random() * (i + 1)
    tmpi = array[i]
    tmpj = array[j]
    array[i] = tmpj
    array[j] = tmpi
  return
