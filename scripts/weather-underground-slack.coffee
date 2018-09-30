# Description:
#   Backlog to Slack

SLACK_TOKEN = process.env.SLACK_TOKEN

module.exports = (robot) ->
  robot.router.post "https://baru-bot.herokuapp.com/weather", (req, res) ->
    room = "test"
    body = req.body

    console.log body

    data =
      text: "test"
      attachments: [
        title: "test"
      ]

    # Slack に投稿
    robot.messageRoom room, data
    res.end "OK"
