# Description:
#   Weather Hacks API から 天気予報情報を取得して返す
#
# Commands:
#   hubot <地名>の天気 - 天気予報情報を返す
#
# Author:
#   hnarita

weathearAreaList = require('../config/weather_area_list.json')
cronJob = require('cron').CronJob
request = require("request")

module.exports = (robot) ->

  robot.respond /(.+)の天気/i, (msg) ->
    city_id = get_city_id(msg.match[1])
    get_weather_info city_id,(err,res,body) ->
      weather_info = JSON.parse body

      forecasts_date = new Date(weather_info.forecasts[0].date)
      days = ["日", "月", "火", "水", "木", "金", "土"]

      data =
        text: "【#{weather_info.title}】"
        attachments: [
          color: "good"
          title: "#{forecasts_date.getFullYear()}年#{forecasts_date.getMonth() + 1}月#{forecasts_date.getDate()}日（#{days[forecasts_date.getDay()]}）  #{weather_info.title}"
          title_link: "#{weather_info.link}"
          thumb_url: "#{weather_info.forecasts[0].image.url}"
          text: "*#{weather_info.forecasts[0].telop}*"
          fields: [
            {
              title: "最高気温"
              value: "#{weather_info.forecasts[0].temperature.max}℃"
              short: true
            },
            {
              title: "最低気温"
              value: "#{weather_info.forecasts[0].temperature.min}℃"
              short: true
            }
          ]
          mrkdwn_in: ["fields","text"]
        ]

      # Slack に投稿
      msg.send data

# Livedoor Weather Hacks API から情報を取得
get_weather_info = (city_id,callback) ->
  apiUrl="http://weather.livedoor.com/forecast/webservice/json/v1"
  options =
    url: apiUrl
    qs: {
      city: city_id
    }
  request.get options, (err,res,body) ->
    if err? or res.statusCode isnt 200
      console.log err
      return
    else
      callback(err,res,body)

# weather_area_list.jsonを使用し、都市名 からCityIdを取得:
get_city_id = (city_name) ->
  for area in weathearAreaList
    for data in area.city
      if data.title == city_name
        return data.id
