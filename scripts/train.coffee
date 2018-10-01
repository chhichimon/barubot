# Description:
#   運行情報 検索
#
# Commands:
#   hubot train all

train_list = require('../config/train_list.json')
cheerio = require 'cheerio-httpcli'
cronJob = require('cron').CronJob

module.exports = (robot) ->

  searchAllTrain = (msg) ->
    # send HTTP request
    baseUrl = 'https://transit.yahoo.co.jp/traininfo/gc/13/'
    cheerio.fetch baseUrl, (err, $, res) ->
      if $('.elmTblLstLine.trouble').find('a').length == 0
        msg.send "事故や遅延情報はありません"
        return
      $('.elmTblLstLine.trouble a').each ->
        url = $(this).attr('href')
        cheerio.fetch url, (err, $, res) ->
          title = ":warning: #{$('h1').text()} #{$('.subText').text()}"
          result = ""
          $('.trouble').each ->
            trouble = $(this).text().trim()
            result += "- " + trouble + "\r\n"
          msg.send "#{title}\r\n#{result}"

  robot.respond /train (.+)/i, (msg) ->
    if msg.match[1] == "all"
      searchAllTrain(msg)
    else
      train_url = get_train_url(msg.match[1])
      searchTrain(train_url, msg)

  searchTrain = (url, msg) ->
    cheerio.fetch url, (err, $, res) ->
      title = "#{$('h1').text()}"
      if $('.icnNormalLarge').length
        msg.send ":ok_woman: #{title}は遅延してないので安心しろ。"
      else
        info = $('.trouble p').text()
        msg.send ":warning: #{title}は遅延しとる。フザケンナ。\n#{info}"

  # cronJobの引数は、秒・分・時間・日・月・曜日の順番
  new cronJob('0 0,10,20,30,40,50 7 * * 1-5', () ->
    baseUrl = 'https://transit.yahoo.co.jp/traininfo/gc/13/'
    allTrainCron(baseUrl)
  ).start()

  new cronJob('0 30,59 18 * * 1-5', () ->
    baseUrl = 'https://transit.yahoo.co.jp/traininfo/gc/13/'
    allTrainCron(baseUrl)
  ).start()

  searchTrainCron = (url) ->
    cheerio.fetch url, (err, $, res) ->
      #路線名(Yahoo!運行情報から正式名称を取得)
      title = "#{$('h1').text()}"
      if $('.icnNormalLarge').length
        # 通常運転の場合
        #robot.send {room: "#random"}, "#{title}は遅延してないので安心しろ。"
      else
        # 通常運転以外の場合
        info = $('.trouble p').text()
        robot.send {room: "talk"}, ":warning: #{title}は遅延しとる。フザケンナ。\n#{info}"

  allTrainCron = (url) ->
    # send HTTP request
    cheerio.fetch url, (err, $, res) ->
      if $('.elmTblLstLine.trouble').find('a').length == 0
        msg.send "事故や遅延情報はないので安心しろ。"
        return
      $('.elmTblLstLine.trouble a').each ->
        url = $(this).attr('href')
        cheerio.fetch url, (err, $, res) ->
          title = ":warning: #{$('h1').text()} #{$('.subText').text()}"
          result = ""
          $('.trouble').each ->
            trouble = $(this).text().trim()
            result += "- " + trouble + "\r\n"
            robot.send {room: "talk"}, ":warning: #{title}は遅延しとる。フザケンナ。\r\n#{result}"

# train_list.jsonを使用し、路線名 からURLを取得
get_train_url = (name) ->
  for train_info in train_list
    if train_info.name == name
      return train_info.url
