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
        thumb_url: "#{body.image_url}"
        title: "#{body.condition}"
        title_link: "#{body.forecast_url}"
        fields: [
          {
            title: "最高気温"
            value: "#{body.high_temp}℃"
            short: true
          },
          {
            title: "最低気温"
            value: "#{body.low_temp}℃"
            short: true
          }
        ]
        mrkdwn_in: ["fields","text"]
      ]

    # Slack に投稿
    robot.messageRoom "test", data
    res.end "OK"
