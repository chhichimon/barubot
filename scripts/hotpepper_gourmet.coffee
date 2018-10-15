# Description:
#   Searches restaurants from Hotpepper.
#     code : budget value
#     B001 : ~2000YEN
#     B002 : 2001~3000YEN
#     B003 : 3001~4000YEN
#     B008 : 4001~5000YEN
#     B004 : 5001~7000YEN
#     B005 : 7001~10000YEN
#     B006 : 10001YEN~
#
#     code : middle_area
#     Y005 : 銀座・有楽町・新橋・築地・月島
#     Y006 : 水道橋・飯田橋・神楽坂
#     Y010 : 東京・大手町・日本橋・人形町
#     Y015 : 上野・御徒町・浅草
#     Y016 : 北千住・日暮里・葛飾・荒川
#     Y017 : 錦糸町・浅草橋・両国・亀戸
#     Y020 : 神田・神保町・秋葉原・御茶ノ水
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

  robot.respond /(グルメ|ご飯)( me)? (.*)/i, (msg) ->
    search_option =
      middle_area: "Y005,Y015,Y016,Y020"

    search_hpr msg.match[3], search_option,(err,res,msg_data) ->
      if msg_data?
        msg.send msg_data
      else
        msg.send "希望の店はないなぁ。妥協してみたら？"

  robot.respond /(lunch|ランチ)( me)? (.*)/i, (msg) ->
    search_option =
      lunch: 1
      middle_area: "Y015,Y016"
      budget: "B001"

    search_hpr msg.match[3], search_option,(err,res,msg_data) ->
      if msg_data?
        msg.send msg_data
      else
        msg.send "希望の店はないなぁ。妥協してみたら？"

  robot.respond /hpr$/, (msg) ->
    search_option =
      middle_area: "Y005,Y015,Y016,Y020"

    search_hpr "酒", search_option,(err,res,msg_data) ->
      msg_data.text = "そろそろ帰ろう。一杯やってく？"
      msg.send msg_data

  # talk部屋に、月〜土 11:30にランチ情報
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
        budget: "B001"

      search_hpr "", search_option,(err,res,msg_data) ->
        msg_data.text = "もうすぐランチやん"
        robot.messageRoom "talk", msg_data
  )

  # talk部屋に、月〜土 18:00にディナー情報
  cronjob = new cron(
    cronTime: "0 0 18 * * 1-5"    # 実行時間：秒・分・時間・日・月・曜日
    start:    true                # すぐにcronのjobを実行するか
    timeZone: "Asia/Tokyo"        # タイムゾーン指定
    onTick: ->                    # 時間が来た時に実行する処理
      search_option =
        middle_area: "Y005,Y015,Y016,Y020"

      search_hpr "酒", search_option,(err,res,msg_data) ->
        msg_data.text = "そろそろ帰ろう。一杯やってく？"
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
    if err? res.statusCode isnt 200
      console.log err
      return
    else
      if parseInt(JSON.parse(body).results.results_returned,10) is 0
        msg_data = null
      else
        shops = JSON.parse(body).results.shop
        shuffle shops
        attachments = []
        cnt = 0
        if shops.length < 4
          cnt = shops.length
        else
          cnt = 4

        for shop in shops[0...cnt]
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
