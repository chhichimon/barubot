# Description:
#   Backlog to Slack

backlogUrl = 'https://usn.backlog.com/'

module.exports = (robot) ->
  robot.router.post "/backlog/:room", (req, res) ->
    room = req.params.room
    body = req.body

    console.log 'body type = ' + body.type
    console.log 'room = ' + room

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
      issue_status: { 1: "未対応", 2: "処理中", 3: "処理済み", 4: "完了" }

      # 完了理由
      resolution: { 0: "対応済み", 1: "対応しない", 2: "無効", 3: "重複", 4: "再現しない" }

      # 投稿メッセージを整形
      url = "#{backlogUrl}view/#{body.project.projectKey}-#{body.content.key_id}"

      # 通知対象者
#      notifications = body.notifications?.map (n) -> " #{n.user.name}"
#      if notifications?.length > 0
#      fields.push(
#        title: "To"
#        value: "#{notifications}"
#      )

      # 課題追加
      if body.type == 1
      # TODO: 課題を作成したユーザーが担当の場合はお知らせに追加されない
      # TODO: そのため、担当が決まっているのも関わらず「未設定」となってしまう
        assigner = (body.notifications.filter (n) -> n.reason == 1)[0]
        fields.push(
          {
            title: "担当"
            value: assigner?.user?.name
          },
          {
            title: "詳細"
            value: body.content.description
          }
        )

      # 課題更新
      if body.content?.changes?
        for change in body.content.changes
          title = null
          value = "#{change.old_value} → #{change.new_value}"
          short = true

          switch change.field
            when "assigner" then title = "担当者変更"
            when "attachment" then title = "添付ファイル変更"
            when "milestone" then title = "マイルストーン変更"
            when "limitDate" then title = "期限日変更"
            when "description"
              title = "詳細変更"
              value = "#{change.old_value}\n ↓ \n#{change.new_value}"
              short = false
            when "status"
              title = "ステータス変更"
              value = "#{issue_status[change.old_value]} → #{issue_status[change.new_value]}"
            when "resolution"
              title = "完了理由変更"
              value = "#{resolution[change.old_value]} → #{resolution[change.new_value]}"

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
          url = "#{backlog_url}downloadAttachment/#{attachment.id}/#{attachment.name}"
          value += "- #{url}\n"
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

      # メッセージ整形
      msg =
        pretext: "{body.createdUser?.name}さんが#{label}しました。"
        color: "#{color}"
        title: "[#{body.project?.projectKey}-#{body.content?.key_id}] #{body.content?.summary}"
        title_link: "#{backlog_url}view/#{body.project?.projectKey}-#{body.content?.key_id}"
        fields: fields

      console.log msg

      # Slack に投稿
      if msg?
        robot.messageRoom room, msg
        res.end "OK"
      else
        robot.messageRoom room, "Backlog integration error."
        res.end "Error"

    catch error
      robot.send
      res.end "Error"
      console.log 'Error'
