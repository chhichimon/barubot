# Description:
#   backlog テスト用
#

BACKLOG_API_KEY = process.env.BACKLOG_API_KEY
SLACK_TOKEN = process.env.SLACK_TOKEN

async = require "async"
cron = require("cron").CronJob

common_function = require "./common_function"
cmn_fn = new common_function()

Backlog = require "./backlog"
backlog = new Backlog()

users_list = require('../config/users.json')
project_list = require('../config/backlog_project_list.json')

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
                    title: "今日も一日がんばりまひょ！"
                    value: messages.join("\n")
                    short: false
                  }
                ]
              ]

            msg.send data


  robot.respond /issues$/, (msg) ->
    cmn_fn.date_format new Date(),'YYYY-MM-DD',(due_date) ->
      data = []
      attachments = []
      total_cnt = 0
      async.map users_list
      , (user,callback) ->
        param =
          statusId:  ["1", "2", "3"]
          assigneeId: ["#{user.backlog_id}"]
          sort: "dueDate"
          dueDateSince: due_date
          dueDateUntil: due_date

        backlog.get_issues param , (err,res,messages) ->
          user_cnt = messages.length
          if user_cnt > 0
            total_cnt += user_cnt
            get_slack_user_icon user.slack_id,SLACK_TOKEN,(user_info_err,user_info_res,user_info_body) ->
              slack_user_info = JSON.parse user_info_body
              user_icon = "#{slack_user_info.profile.image_24}"
              attachments.push(
                color: "#ff0000"
                author_name: "#{user.name}さん #{user_cnt}件"
                author_link: "#{user.backlog_url}"
                author_icon: "#{user_icon}"
                text: messages.join("\n")
              )

              attachment =
                color: "#ff0000"
                author_name: "#{user.name}さん #{user_cnt}件"
                author_link: "#{user.backlog_url}"
                author_icon: "#{user_icon}"
                text: messages.join("\n")

          else
            attachment = {}

          callback(null,attachment)

      , (err,result) ->

        # メッセージ整形
        if total_cnt > 0
          cmn_fn.date_format new Date(),'YYYY%2FMM%2FDD',(str_today) ->
            data =
              text: ":eyes: <https://usn.backlog.com/FindIssueAllOver.action?condition.projectId=11507&condition.statusId=1&condition.statusId=2&condition.statusId=3&condition.limit=100&condition.offset=0&condition.sort=LIMIT_DATE&condition.order=false&condition.simpleSearch=false&condition.allOver=true&condition.limitDateRange.begin=#{str_today}&condition.limitDateRange.end=#{str_today}|#{total_cnt}件の課題が今日までやで> :eyes:"
              attachments: attachments
        else
          data =
            text: "今日までの課題はなし！ :zawazawa:"

        msg.send data

  # プロジェクトレポート
  robot.respond /report$/, (msg) ->

    data = []
    message = ":backlog: *プロジェクトレポート作ったったよ* :tada:\n"
    # 全プロジェクトのレポート
    backlog.get_backlog_report_message null, (err,res,message_text) ->
      message += message_text + "\n"

      # 各プロジェクト毎のレポート
      async.map project_list
      , (project,callback) ->
        backlog.get_backlog_report_message project, (err,res,message_text) ->
          callback(null,message_text)
      , (err,result) ->
        message += result.join("\n")
        data =
          text: message
          mrkdwn: true
        # Slackに投稿
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




# プロジェクト毎の残課題件数を取得し、レポートメッセージを生成する
get_backlog_report_message = (project_info,callback) ->
  message_text = ""
  projectId =[]
  project_name = ""

  unless project_info?
    project_name = "全プロジェクト"
  else
    projectId.push project_info.id
    project_name = project_info.name

  today_str = ""
  yesterday_str = ""

  countlist =
    not_started: 0
    processing: 0
    processed: 0
    expired: 0
    today_period: 0
    incomplete: 0


  cmn_fn.date_format new Date(),'YYYY-MM-DD',(due_date_str) ->
    today_str = due_date_str

    cmn_fn.date_add new Date(), -1, 'DD', (due_date) ->
      cmn_fn.date_format due_date,'YYYY-MM-DD',(due_date_str) ->
        yesterday_str = due_date_str

        # 未着手件数
        param =
          projectId: projectId
          statusId: ["1"]
        backlog.get_issues_count param , (err,res,issues_count) ->
          countlist.not_started = issues_count
          # 処理中件数
          param =
            projectId: projectId
            statusId: ["2"]
          backlog.get_issues_count param , (err,res,issues_count) ->
            countlist.processing = issues_count
            # 処理済み件数
            param =
              projectId: projectId
              statusId: ["3"]
            backlog.get_issues_count param , (err,res,issues_count) ->
              countlist.processed = issues_count

              # 期限オーバー件数
              param =
                projectId: projectId
                statusId: ["1", "2", "3"]
                dueDateUntil: yesterday_str
              backlog.get_issues_count param, (err,res,issues_count) ->
                countlist.expired = issues_count

                # 本日期限件数
                param =
                  projectId: projectId
                  statusId: ["1", "2", "3"]
                  dueDateSince: today_str
                  dueDateUntil: today_str
                backlog.get_issues_count param, (err,res,issues_count) ->
                  countlist.today_period = issues_count

                  # 未完了件数
                  countlist.incomplete = countlist.not_started + countlist.processing + countlist.processed

                  # メッセージ整形
                  message_text += ">#{project_name}\n"
                  message_text += "```\n"
                  message_text += "未完了 #{countlist.incomplete}件 ： □ 未着手 #{countlist.not_started}件\t■ 処理中 #{countlist.processing}件\t■ 処理済み #{countlist.processed}件\n本日期限 #{countlist.today_period}件\t期限オーバー #{countlist.expired}件\n"
                  message_text += "```\n"

                  callback(err,res,message_text)
