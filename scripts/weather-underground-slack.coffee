# Description:
#   Backlog to Slack

module.exports = (robot) ->
  robot.router.post "/weather", (req, res) ->
    body = req.body

    # メッセージ整形
    data =
      attachments: [
        color: "#07b3de"
        thumb_url: "#{body.image_url}"
        title: "今日の台東区の天気"
        title_link: "#{body.forecast_url}"
        text: "#{body.condition}\n" + "最高気温：#{body.high_temp}℃\n" + "最低気温：#{body.low_temp}℃\n" + "\n#{body.check_time}"
      ]

    # Slack に投稿
    robot.messageRoom "test", data
    res.end "OK"
