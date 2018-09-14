# Description:
#   Hello World!
#
# Commands:
#   hubot hello : Returns "world!"

module.exports = (robot) ->
  robot.respond /hello/i, (msg) ->
    msg.send "world!"
