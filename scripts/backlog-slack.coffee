# Description:
#   Backlog to Slack

BACKLOG_API_KEY = process.env.BACKLOG_API_KEY
SLACK_TOKEN = process.env.SLACK_TOKEN

users_list = require('../config/users.json')
update_types = require('../config/backlog_update_type.json')

async = require "async"
req_cron_job = require("cron").CronJob
req_backlog = require "./backlog"
req_cmn_fn = require "./common_function"

cmn_fn = new req_cmn_fn()
backlog = new req_backlog()

backlogUrl = 'https://usn.backlog.com/'

module.exports = (robot) ->

  # Backlog更新情報をSlackに投稿する
  robot.router.post "/backlog/:room", (req, res) ->
    room = req.params.room
    body = req.body

    fields = []
    user_icon = ""

    # 更新情報を識別
    for update_type in update_types
      if update_type.type_no is body.type
        label = update_type.type_name
        color = update_type.color

    try

      # 課題ステータス
      issue_status =
        1: "未対応"
        2: "処理中"
        3: "処理済み"
        4: "完了"

      # 完了理由
      resolution =
        0: "対応済み"
        1: "対応しない"
        2: "無効"
        3: "重複"
        4: "再現しない"

      # 優先度
      issue_priority =
        2: "高"
        3: "中"
        4: "低"

      # 課題情報を取得する
      backlog.get_issue "#{body.content.id}",(uissue_err, issue_res, issue_body) ->
        issue_info = JSON.parse issue_body

        # 課題追加
        if body.type == 1
          # 詳細
          if issue_info.description?
            fields.push(
              title: "詳細"
              value: "#{issue_info.description}"
              short: false
            )

          # 担当
          fields.push(
            title: "担当者"
            value: "#{decorate(issue_info.assignee?.name)}"
            short: true
          )
          # 期限日
          fields.push(
            title: "期限日"
            value: "#{decorate(issue_info.dueDate)}".replace(/(T.*Z)/g,"")
            short: true
          )

          # ステータス
          fields.push(
            title: "ステータス"
            value: "#{decorate(issue_status[issue_info.status.id])}"
            short: true
          )

        # 課題変更点羅列
        if body.content?.changes?
          for change in body.content.changes
            title = null
            value = "#{decorate(change.old_value)} → #{decorate(change.new_value)}"
            short = true

            switch change.field
              when "status"
                title = "ステータス"
                value = "#{decorate(issue_status[change.old_value])} → #{decorate(issue_status[change.new_value])}"
              when "description"
                title = "詳細"
                value = "#{decorate(change.old_value)}\n ↓ \n#{decorate(change.new_value)}"
                short = false
              when "assigner" then title = "担当者"
              when "startDate" then title = "開始日"
              when "limitDate" then title = "期限日"
              when "milestone" then title = "マイルストーン"
              when "resolution"
                title = "完了理由変更"
                value = "#{decorate(resolution[change.old_value])} → #{decorate(resolution[change.new_value])}"
              when "estimatedHours" then title = "予定時間"
              when "actualHours" then title = "実績時間"
              when "priority"
                title = "優先度"
                value = "#{decorate(issue_priority[change.old_value])} → #{decorate(issue_priority[change.new_value])}"
              when "attachment" then title = "添付ファイル"

            if title?
              fields.push(
                title: title
                value: value
                short: short
              )

        # 添付ファイル
        if body.content?.attachments?
          value = ""
          for attachment in body.content.attachments
            url = "#{backlogUrl}downloadAttachment/#{attachment.id}/#{attachment.name}"
            value += "- #{url}\n"

          if value != ""
            fields.push(
              title: "添付ファイル"
              value: value
            )

        # コメント
        if body.content?.comment? && body.content.comment.content?.trim() != ""
          fields.push(
            title: "コメント"
            value: body.content.comment.content
          )

        # 通知対象者
        if body.notifications?
          value = ""
          for notification in body.notifications
            userid = ""
            userid = get_slack_id_by_backlog_id(notification.user.id)
            if userid == ""
              userid = "#{notification.user.name}"
            value += "<@#{userid}>\n"

          if value != ""
            fields.push(
              title: "お知らせした人"
              value: value
            )

        userid = get_slack_id_by_backlog_id(body.createdUser.id)
        user_url = get_backlog_user_url(body.createdUser.id)

        get_slack_user_icon userid,SLACK_TOKEN,(user_info_err,user_info_res,user_info_body) ->
          user_info = JSON.parse user_info_body
          user_icon = "#{user_info.profile.image_24}"

          # Slack投稿メッセージを整形
          data =
            text: "Backlog *#{body.project.name}*"
            attachments: [
              author_name: "#{body.createdUser?.name}さんが#{label}しました。"
              author_link: "#{user_url}"
              author_icon: "#{user_icon}"
              color: "#{color}"
              title: "[#{body.project?.projectKey}-#{body.content?.key_id}] #{body.content?.summary}"
              title_link: "#{backlogUrl}view/#{body.project?.projectKey}-#{body.content?.key_id}"
              fields: fields
              mrkdwn_in: ["fields","text"]
            ]

          # Slack に投稿
          robot.messageRoom room, data
          res.end "OK"

    catch error
      console.log error
      robot.messageRoom room, "error:" + error
      robot.send
      res.end "Error"


  # 月〜土曜 8:55 にBacklogのスターを集計してSlackに投稿する
  cronjob = new req_cron_job(
    cronTime: "0 55 8 * * 1-6"      # 実行時間：秒・分・時間・日・月・曜日
    start:    true                # すぐにcronのjobを実行するか
    timeZone: "Asia/Tokyo"        # タイムゾーン指定
    onTick: ->                    # 時間が来た時に実行する処理
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

              robot.messageRoom "talk", data

  )

  # 月〜土曜 9:00 にBacklog本日期限課題をSlackに投稿する
  cronjob = new req_cron_job(
    cronTime: "0 0 9 * * 1-6"      # 実行時間：秒・分・時間・日・月・曜日
    start:    true                # すぐにcronのjobを実行するか
    timeZone: "Asia/Tokyo"        # タイムゾーン指定
    onTick: ->                    # 時間が来た時に実行する処理
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
              text: "今日までの課題はあれへん :zawazawa:"

          robot.messageRoom "talk", data

  )


  # 月〜土曜 9:02 にBacklog残課題件数をSlackに投稿する
  cronjob = new req_cron_job(
    cronTime: "0 2 9 * * 1-6"      # 実行時間：秒・分・時間・日・月・曜日
    start:    true                # すぐにcronのjobを実行するか
    timeZone: "Asia/Tokyo"        # タイムゾーン指定
    onTick: ->                    # 時間が来た時に実行する処理

      messages = []
      data = []
      cmn_fn.date_add new Date(), -1, 'DD', (due_date) ->
        cmn_fn.date_format due_date,'YYYY-MM-DD',(due_date_str) ->

          # 未完了件数
          param =
            statusId: ["1", "2", "3"]
          backlog.get_issues_count param , (err,res,issues_count) ->
            messages.push "未完了：#{issues_count}件"

            # 期限オーバー件数
            param.dueDateUntil = due_date_str
            backlog.get_issues_count param , (err,res,issues_count) ->
              messages.push "期限オーバー：#{issues_count}件"

              # メッセージ整形
              data =
                attachments: [
                  color: "#ff0000"
                  pretext: ":fire: 残っとる課題件数やで :fire:"
                  text: messages.join("\n")
                ]

              # Slackに投稿
              robot.messageRoom "talk", data

  )


#----------------------------------------------------------------------
# 課題のステータス名を検索
# search_task_status_name = (task_status_json, state_id) ->
#  return __search_name_by_id(task_status_json, state_id)

# 完了理由のステータス名を検索
#search_task_resolution_name = (task_resolution_json, resolution_id) ->
#  return __search_name_by_id(task_resolution_json, resolution_id)

# 空文字の場合、未設定を返す
decorate = (s) ->
  if !s? || s.trim?() is ""
    return "未設定"
  return s

# backlog_idからslack_idを取得
get_slack_id_by_backlog_id = (id) ->
  for user_info in users_list
    return user_info.slack_id if user_info.backlog_id == id
  return ""

# backlog_idからbacklog_urlを取得
get_backlog_user_url = (id) ->
  for user_info in users_list
    return user_info.backlog_url if user_info.backlog_id == id
  return ""

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
