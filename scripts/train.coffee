# Description:
#   wikipedia 検索
#
# Commands:
#   hubot train


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
    target = msg.match[1]
    # 京浜東北線
    jr_kt = 'http://transit.yahoo.co.jp/traininfo/detail/22/0/'
    # 京急本線
    kq = 'https://transit.yahoo.co.jp/traininfo/detail/120/0/'
    if target == "kq"
      searchTrain(kq, msg)
    else if target == "jr_kt"
      searchTrain(jr_kt, msg)
    else if target == "all"
      searchAllTrain(msg)
    else
      msg.send "#{target}は検索できなし( ˘ω˘ ) usage: @world_conquistador [kq | jr_kt | all]"

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
    # 京急本線(Yahoo!運行情報から選択したURLを設定する。)
    kq = 'https://transit.yahoo.co.jp/traininfo/detail/120/0/'
    # 京浜東北線
    jr_kt = 'http://transit.yahoo.co.jp/traininfo/detail/22/0/'
    searchTrainCron(kq)
    searchTrainCron(jr_kt)
  ).start()

  new cronJob('0 30,59 18 * * 1-5', () ->
    # 京急本線(Yahoo!運行情報から選択したURLを設定する。)
    kq = 'https://transit.yahoo.co.jp/traininfo/detail/120/0/'
    # 京浜東北線
    jr_kt = 'http://transit.yahoo.co.jp/traininfo/detail/22/0/'
    searchTrainCron(kq)
    searchTrainCron(jr_kt)
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
        robot.send {room: "#train_info"}, ":warning: #{title}は遅延しとる。フザケンナ。\n#{info}"
