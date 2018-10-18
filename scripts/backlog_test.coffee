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
    today = new Date()
    date_span = -1
    date_span_text = "昨日"
    if today.getDay() is 1
      date_span = -7
      date_span_text = "先週"

    cmn_fn.date_add new Date(), date_span, 'DD', (since_date) ->
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

              messages.push ("#{star.name}　　　　　　　　").slice(0,7) + "さん " + ("   #{star.stars}").slice(-3) + "スター #{mark}"

            # メッセージ整形
            data =
              attachments: [
                color: "#ffcc66"
                title: ":star2: #{date_span_text}のスター獲得ランキング :star2:"
                title_link: "https://backlog.com/ja/help/usersguide/star/userguide456/"
                fields: [
                  {
                    title: "今日も一日がんばりましょう！"
                    value: messages.join("\n")
                    short: false
                  }
                ]
              ]

            msg.send data


  robot.respond /issues$/, (msg) ->
    cmn_fn.date_format new Date(),'YYYY-MM-DD',(due_date) ->
      data = []
      total_cnt = 0
      for user_info in users_list
        param =
          statusId:  ["1", "2", "3"]
          assigneeId:["#{user_info.backlog_id}"]
          sort: "dueDate"
          dueDateSince: due_date
          dueDateUntil: due_date
        backlog.getIssues(param)
        .then (messages) ->
          user_cnt = messages.length
          if user_cnt > 0
            total_cnt += user_cnt
            get_slack_user_icon userid,SLACK_TOKEN,(user_info_err,user_info_res,user_info_body) ->
              slack_user_info = JSON.parse user_info_body
              user_icon = "#{slack_user_info.profile.image_24}"

            attachments.push(
              color: "#ff0000"
              author_name": "#{user_info.name}さん #{user_cnt}件"
              author_link": "#{user_info.backlog_url}"
              author_icon": "#{user_icon}"
              text: messages.join("\n")
            )

      # メッセージ整形
      if total_cnt > 0

        cmn_fn.date_format new Date(),'YYYY%2FMM%2FDD',(str_today) ->
        data =
          text: "<https://usn.backlog.com/FindIssueAllOver.action?condition.projectId=11507&condition.statusId=1&condition.statusId=2&condition.statusId=3&condition.limit=100&condition.offset=0&condition.sort=LIMIT_DATE&condition.order=false&condition.simpleSearch=false&condition.allOver=true&condition.limitDateRange.begin=#{str_today}&condition.limitDateRange.end=#{str_today}|#{total_cnt}件の課題が今日までやで> :gogogo:"
          attachments: attachments
      else
        data =
          text: "今日までの課題はないねん :zawazawa:"

      msg.send data


# Slackからユーザーアイコンを取得
get_slack_user_icon = (id,slack_token,callback) ->
  # 作成者情報をslackから取得
  apiUrl="https://slack.com/api/users.profile.get"
  request = require("request")
  options =
    url: apiUrl
    qs: {
      token: slack_token
      user: id
    }

  request.get options, (err,res,body) ->
    if err? or res.statusCode isnt 200
      console.log err
      return
    else
      callback(err,res,body)
