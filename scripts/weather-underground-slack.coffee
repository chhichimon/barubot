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
        text: "#{body.condition}"
        title: "今日の台東区の天気"
        title_link: "#{body.forecast_url}"
        fields: [
          {
            title: "最高気温"
            value: "#{body.high_temp}℃"
            short: false
          },
          {
            title: "最低気温"
            value: "#{body.low_temp}℃"
            short: false
          },
          {
            title: "更新日時"
            value: "#{body.check_time}℃"
            short: false
          }
        ]
        mrkdwn_in: ["fields","text"]
      ]

    # Slack に投稿
    robot.messageRoom "test", data
    res.end "OK"
