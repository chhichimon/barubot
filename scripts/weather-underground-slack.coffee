# Description:
#   Backlog to Slack

SLACK_TOKEN = process.env.SLACK_TOKEN

module.exports = (robot) ->
  robot.router.post "/weather", (req, res) ->
    room = "test"

    console.log req.body
