# Description:
#   Backlog to Slack

SLACK_TOKEN = process.env.SLACK_TOKEN

module.exports = (robot) ->
  robot.router.post "https://baru-bot.herokuapp.com/weather", (req, res) ->
    room = "test"
    body = req.body

    console.log body

###
      # メッセージ整形
      data =
        text: ""
        attachments: [
          title: "[#{body.project?.projectKey}-#{body.content?.key_id}] #{body.content?.summary}"
          title_link: "#{backlogUrl}view/#{body.project?.projectKey}-#{body.content?.key_id}"
          fields: fields
          mrkdwn_in: ["fields","text"]
          thumb_url: "#{weather_info.forecasts[0].image.url}"
        ]
###
      data =
        text: "test"
        attachments: [
          title: "test"
        ]

      # Slack に投稿
      robot.messageRoom room, data
      res.end "OK"
