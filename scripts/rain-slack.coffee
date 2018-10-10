# Description:
#   Backlog to Slack

module.exports = (robot) ->
  robot.router.post "/rain", (req, res) ->
    body = req.body

    # メッセージ整形
    data =
      attachments: [
        color: "#0040ff"
        thumb_url: "#{body.image_url}"
        title: "雨が降ってきたよ！"
        title_link: "#{body.forecast_url}"
        text: "気温：#{body.temp}℃"+ "\n\n#{body.check_time}"
      ]

    # Slack に投稿
    robot.messageRoom "talk", data
    res.end "OK"
