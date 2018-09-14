# Description:
#   <description of the scripts functionality>
#
# Dependencies:
#   "<module name>": "<module version>"
#
# Configuration:
#   LIST_OF_ENV_VARS_TO_SET
#
# Commands:
#   hubot <trigger> - <what the respond trigger does>
#   <trigger> - <what the hear trigger does>
#
# Notes:
#   <optional notes required for the script>
#
# Author:
#   <github username of the original script author>
module.exports = (robot) ->
  robot.hear /(ばる|バル)/i, (res) ->
    res.send res.random ["今日は？", "ん？"]
  robot.hear /おはよう/i, (res) ->
    res.send res.random ["おはよう！", "オッス!", "Good Morning!"]
  robot.hear /おやすみ/i, (res) ->
    res.send res.random ["おやすみ！", "み!"]
