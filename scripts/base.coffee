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
  robot.hear /(�΂�|�o��)/i, (res) ->
    res.send res.random ["�����́H", "��H"]
  robot.hear /���͂悤/i, (res) ->
    res.send res.random ["���͂悤�I", "�I�b�X!", "Good Morning!"]
  robot.hear /���₷��/i, (res) ->
    res.send res.random ["���₷�݁I", "��!"]
