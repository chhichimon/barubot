# Description:
#   Backlog to Slack

module.exports = (robot) ->
  robot.router.post "/weather", (req, res) ->
    body = req.body

    # メッセージ整形
    data =
      text: "今日の天気"
      attachments: [
        thumb_url: "#{body.value1}"
        title: "#{body.value3}"
        title_link: "#{body.value2}"
        mrkdwn_in: ["fields","text"]
      ]

    # Slack に投稿
    robot.messageRoom "test", data
    res.end "OK"
