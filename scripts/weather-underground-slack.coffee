# Description:
#   Backlog to Slack

module.exports = (robot) ->
  robot.router.post "/weather", (req, res) ->

    console.log "#{req.body}"
