# Description:
#   backlog テスト用
#

async = require "async"
cron = require("cron").CronJob

common_function = require "./common_function"
cmn_fn = new common_function()

Backlog = require "./backlog"
backlog = new Backlog()

users_list = require('../config/users.json')

module.exports = (robot) ->

  robot.respond /(.+)の課題$/, (msg) ->
    name = msg.match[1]

    for user_info in users_list
      user_id = user_info.backlog_id if user_info.name == name

    param =
      statusId:  ["1", "2", "3"]
      assigneeId:["#{user_id}"]

    backlog.getIssues(param)
    .then (messages) ->
      msg.send messages.join("\n")

  # スター集計
  robot.respond /star$/, (msg) ->
    cmn_fn.date_add new Date(), -7, 'DD', (since_date) ->
      cmn_fn.date_format since_date,'YYYY-MM-DD',(since_str) ->
        cmn_fn.date_format new Date(),'YYYY-MM-DD',(until_str) ->
          stars_list = []
          async.map users_list
          , (user,callback) ->
            backlog.get_stars user.backlog_id, since_str, until_str, (err,res,stars) ->
              stars_list.push(
                name: "#{user.name}"
                stars: stars
              )
              result =
                name: "#{user.name}"
                stars: stars

              callback(null,result)
          , (err,result) ->

            compare_stars = (a, b) ->
              b.stars - a.stars

            stars_list.sort compare_stars
            messages = []

            for star in stars_list
              mark = ""
              if parseInt(star.stars,10) > 0
                for i in [0...parseInt(star.stars,10)]
                  mark += ":star:"

              messages.push "#{star.name} さん #{star.stars} スター  #{mark}"

            # メッセージ整形
            data =
              attachments: [
                color: "#ffcc66"
                title: "昨日のスター獲得ランキング発表！！"
                title_link: "https://backlog.com/ja/help/usersguide/star/userguide456/"
                thumb_url: "https://pics.prcm.jp/673b2edcd5b2c/48639059/gif/48639059.gif"
                fields: [
                  {
                    title: "今日も一日がんばりましょう！"
                    value: messages.join("\n")
                    short: false
                  }
                ]
              ]

            msg.send data

  cronjob = new cron(
    cronTime: "0 55 8 * * *"      # 実行時間：秒・分・時間・日・月・曜日
    start:    true                # すぐにcronのjobを実行するか
    timeZone: "Asia/Tokyo"        # タイムゾーン指定
    onTick: ->                    # 時間が来た時に実行する処理
      cmn_fn.date_add new Date(), -1, 'DD', (since_date) ->
        cmn_fn.date_format since_date,'YYYY-MM-DD',(since_str) ->
          cmn_fn.date_format new Date(),'YYYY-MM-DD',(until_str) ->
            stars_list = []
            async.map users_list
            , (user,callback) ->
              backlog.get_stars user.backlog_id, since_str, until_str, (err,res,stars) ->
                stars_list.push(
                  name: "#{user.name}"
                  stars: stars
                )
                result =
                  name: "#{user.name}"
                  stars: stars

                callback(null,result)
            , (err,result) ->

              compare_stars = (a, b) ->
                b.stars - a.stars

              stars_list.sort compare_stars
              messages = []

              for star in stars_list
                mark = ""
                if parseInt(star.stars,10) > 0
                  for i in [0...parseInt(star.stars,10)]
                    mark += ":star:"
                messages.push "#{star.name} さん #{star.stars} スター"

              # メッセージ整形
              data =
                attachments: [
                  color: "#ffcc66"
                  title: "昨日のスター獲得ランキング発表！！"
                  title_link: "https://backlog.com/ja/help/usersguide/star/userguide456/"
                  image_url: "https://pics.prcm.jp/673b2edcd5b2c/48639059/gif/48639059.gif"
                  fields: [
                    {
                      title: "今日も一日がんばりましょう！"
                      value: messages.join("\n")
                      short: false
                    }
                  ]
                ]

              robot.messageRoom "talk", data

  )
