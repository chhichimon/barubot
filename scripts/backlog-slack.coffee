# Description:
#   Backlog to Slack

backlogUrl = 'https://usn.backlog.com/'
BACKLOG_API_KEY = process.env.BACKLOG_API_KEY
SLACK_TOKEN = process.env.SLACK_TOKEN

module.exports = (robot) ->
  robot.router.post "/backlog/:room", (req, res) ->
    room = req.params.room
    body = req.body
    fields = []
    idmap = []
    idmap = [
      # 片野
      {
        backlogUserId: 15536
        slackUserId: "U95TZK4HX"
      },
      # h.narita
      {
        backlogUserId: 29037
        slackUserId: "U3YNUQBFT"
      },
      # nakagawa
      {
        backlogUserId: 29041
        slackUserId: "U3Z7NT400"
      },
      # sosa
      {
        backlogUserId: 29036
        slackUserId: "U81SFBDT5"
      },
      # yamagata
      {
        backlogUserId: 29038
        slackUserId: "U3ZLRJ37S"
      },
      # takeishi
      {
        backlogUserId: 29043
        slackUserId: "U821BJ9S9"
      },
      # 佐藤　晴香
      {
        backlogUserId: 29039
        slackUserId: "U8XQ58R45"
      },
      # N.Motoki
      {
        backlogUserId: 29139
        slackUserId: "U8WUE53S6"
      },
      # y.fukumoto
      {
        backlogUserId: 29119
        slackUserId: "U4JKGV1QX"
      },
      # ozawa
      {
        backlogUserId: 15539
        slackUserId: "UD17ESETX"
      }
    ]

    try
      switch body.type
        when 1
          label = '課題を追加'
          color = '#36a64f'
        when 2
          label = '課題を更新'
          color = '#0c6bee'
        when 3
          label = '課題にコメント'
          color = '#ecee0c'
        when 8
          label = '共有ファイルを追加'
          color = '#0c6bee'
        when 9
          label = '共有ファイルを更新'
          color = '#0c6bee'
        when 10
          label = '共有ファイルを削除'
          color = '#ff0000'
        when 14
          label = '課題をまとめて更新'
          color = '#ff7400'
        else
          # 上記以外はスルー
          return

      # 課題ステータス
      issue_status = { 1: "未対応", 2: "処理中", 3: "処理済み", 4: "完了" }

      # 完了理由
      resolution = { 0: "対応済み", 1: "対応しない", 2: "無効", 3: "重複", 4: "再現しない" }

      # 投稿メッセージを整形
      url = "#{backlogUrl}view/#{body.project.projectKey}-#{body.content.key_id}"

      # 課題追加
      if body.type == 1
        # 課題情報を取得する
        apiUrl="#{backlogUrl}api/v2/issues/#{body.content.id}"
        request = require("request")
        options =
          url: apiUrl
          qs: {
            apiKey: BACKLOG_API_KEY
          }
#          json: true

        request.get options, (err, res, issuebody) ->
          if err?
            console.log err
            return
          else
            console.log "************* issuebody : #{issuebody}"
            issueInfo = JSON.parse issuebody
            console.log "************* issuebody -> parse : #{issueInfo.description}"

          # 詳細
          if issueInfo.description?
            fields.push(
              title: "詳細"
              value: issueInfo.description
              short: false
            )
          # 担当
          fields.push(
            title: "担当者"
            value: decorate(issueInfo.assignee)
            short: true
          )
          # 期限日
          fields.push(
            title: "期限日"
            value: decorate(issueInfo.dueDate)
            short: true
          )
          # ステータス
          fields.push(
            title: "ステータス"
            value: decorate(issue_status[issueInfo.status.id])
            short: true
          )
          console.log "************* fields : #{fields}"

      # 課題更新
      if body.content?.changes?
        for change in body.content.changes
          title = null
          value = "#{decorate(change.old_value)} → #{decorate(change.new_value)}"
          short = true

          switch change.field
            when "assigner" then title = "担当者変更"
            when "attachment" then title = "添付ファイル変更"
            when "milestone" then title = "マイルストーン変更"
            when "limitDate" then title = "期限日変更"
            when "description"
              title = "詳細変更"
              value = "#{decorate(change.old_value)}\n ↓ \n#{decorate(change.new_value)}"
              short = false
            when "status"
              title = "ステータス変更"
              value = "#{decorate(issue_status[change.old_value])} → #{decorate(issue_status[change.new_value])}"
            when "resolution"
              title = "完了理由変更"
              value = "#{decorate(resolution[change.old_value])} → #{decorate(resolution[change.new_value])}"

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
          userid = get_slack_id_by_backlog_id(notification.user.id,idmap)
          if userid == ""
            userid = "#{notification.user.name}"
          value += "<@#{userid}>\n"

        if value != ""
          fields.push(
              title: "お知らせした人"
              value: value
          )

      user_icon = get_slack_user_icon(get_slack_id_by_backlog_id(body.createdUser.id,idmap),SLACK_TOKEN)
      console.log "************* user_icon : #{user_icon}"

      # メッセージ整形
      data =
        text: "Backlog *#{body.project.name}*"
        attachments: [
          author_name: "#{body.createdUser?.name}さんが#{label}しました。"
          author_icon: "#{user_icon}"
          color: "#{color}"
          title: "[#{body.project?.projectKey}-#{body.content?.key_id}] #{body.content?.summary}"
          title_link: "#{backlogUrl}view/#{body.project?.projectKey}-#{body.content?.key_id}"
          fields: fields
          mrkdwn_in: ["fields","text"]
        ]

      console.log data

      # Slack に投稿
      robot.messageRoom room, data
      res.end "OK"

    catch error
      console.log error
      robot.messageRoom room, "error:" + error
      robot.send
      res.end "Error"


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

# idからSlackのユーザー名を取得
get_slack_id_by_backlog_id = (id , json) ->
  return "" if json == null

  for val in json
    return val.slackUserId if val.backlogUserId == id
  return ""


# Slackからユーザーアイコンを取得
get_slack_user_icon = (id,slack_token) ->
  # 作成者情報をslackから取得
  apiUrl="https://slack.com/api/users.profile.get"
  request = require("request")
  options =
    url: apiUrl
    qs: {
      token: slack_token
      user: id
    }
#    json: true

  request.get options, (err,res,userInfo) ->
    if err? or res.statusCode isnt 200
      console.log err
      return
    else
      console.log "************* userInfo : #{userInfo}"
      data = JSON.parse userInfo
      console.log "************* userInfo.profile.image_24 -> parse : #{data.profile.image_24}"
      ret = "#{data.profile.image_24}"
