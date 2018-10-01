# Description:
#   Backlog to Slack

bodyParser = require 'body-parser'

module.exports = (robot) ->
  robot.router.post "/weather", bodyParser.text(), (req, res) ->

    body = if req.body then JSON.parse req.body else {}
    console.log body
