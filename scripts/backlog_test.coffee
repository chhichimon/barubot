# Description:
#   Example scripts for you to examine and try out.
#
# Notes:
#   They are commented out by default, because most of them are pretty silly and
#   wouldn't be useful and amusing enough for day to day huboting.
#   Uncomment the ones you want to try and experiment with.
#
#   These are from the scripting documentation: https://github.com/github/hubot/blob/master/docs/scripting.md

cron = require('cron').CronJob
Backlog = require "./backlog"
backlog = new Backlog()
request = require "request"

module.exports = (robot) ->

  robot.respond /課題を確認$/, (msg) ->
    backlog.getIssues("statusId": ["1", "2", "3"])
    .then (messages) ->
      msg.send messages.join("\n")
