# Description:
#   Backlog to Slack

module.exports = (robot) ->
  robot.router.post "/weather", (req, res) ->
    body = req.body

    # メッセージ整形
    data =
      text: "今日の天気"
      attachments: [
        color: "#07b3de"
        thumb_url: "#{body.value3}"
        title: "#{body.value1}"
        text: "#{body.value2}"
      ]

    # Slack に投稿
    robot.messageRoom "test", data
    res.end "OK"
