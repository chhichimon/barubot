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
users_list = require('../config/users.json')
request = require "request"

module.exports = (robot) ->

  robot.respond /課題を確認$/, (msg) ->
    backlog.getIssues("statusId": ["1", "2", "3"])
    .then (messages) ->
      msg.send messages.join("\n")

  robot.respond /スター集計$/, (msg) ->
    since_date = new Date()
    since_date = add_date( since_date, -1, 'DD')
    since = format_date(since_date,'YYYY-MM-DD')

    messages = []
    for user in users_list
      backlog.get_stars(user.backlog_id,since,since)
      messages.push("#{user.name} : #{backlog.get_stars(user.backlog_id,since,since)}")

      msg.send messages.join("\n")


###*
 * 日付をフォーマットする
 * @param  {Date}   date     日付
 * @param  {String} [format] フォーマット
 * @return {String}          フォーマット済み日付
###
format_date = (date, format = 'YYYY-MM-DD hh:mm:ss.SSS') ->
  format = format.replace /YYYY/g, date.getFullYear()
  format = format.replace /MM/g, ('0' + (date.getMonth() + 1)).slice(-2)
  format = format.replace /DD/g, ('0' + date.getDate()).slice(-2)
  format = format.replace /hh/g, ('0' + date.getHours()).slice(-2)
  format = format.replace /mm/g, ('0' + date.getMinutes()).slice(-2)
  format = format.replace /ss/g, ('0' + date.getSeconds()).slice(-2)
  if format.match /S/g
    milliSeconds = ('00' + date.getMilliseconds()).slice(-3)
    length = format.match(/S/g).length
    format.replace /S/, milliSeconds.substring(i, i + 1) for i in [0...length]
  return format

###*
 * 日付を加算する
 * @param  {Date}   date       日付
 * @param  {Number} num        加算数
 * @param  {String} [interval] 加算する単位
 * @return {Date}              加算後日付
###
add_date = (date, num, interval) ->
  switch interval
    when 'YYYY'
      date.setYear date.getYear() + num
    when 'MM'
      date.setMonth date.getMonth() + num
    when 'hh'
      date.setHours date.getHours() + num
    when 'mm'
      date.setMinutes date.getMinutes() + num
    when 'ss'
      date.setSeconds date.getSeconds() + num
    else
      date.setDate date.getDate() + num
  return date
