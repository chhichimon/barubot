# Description:
#   backlog テスト用
#

request = require "request"
cron = require('cron').CronJob
common_function = require "./common_function"
cmn_fn = new common_function()

Backlog = require "./backlog"
backlog = new Backlog()
users_list = require('../config/users.json')

module.exports = (robot) ->

  robot.respond /課題を確認$/, (msg) ->
    backlog.getIssues("statusId": ["1", "2", "3"])
    .then (messages) ->
      msg.send messages.join("\n")

  robot.respond /スター集計$/, (msg) ->
    d = new Date()
    cmn_fn.add_date( d, -1, 'DD')
    .then(since_date) ->
      cmn_fn.format_date(since_date,'YYYY-MM-DD')
      .then (since_str) ->
        cmn_fn.format_date(d,'YYYY-MM-DD')
        .then(until_str) ->

          stars_list = []
          for user in users_list
            backlog.get_stars(user.backlog_id,since_str,until_str)
            .then(stars) ->

              stars_list.push(
                name: "#{user.name}"
                stars: stars
              )

          compare_stars = (a, b) ->
            b.stars - a.stars

          stars_list.sortcompare_stars

          msg.send stars_list.join("\n")
