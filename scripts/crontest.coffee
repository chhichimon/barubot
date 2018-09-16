# Description:
#   cron


cronJob = require('cron').CronJob

module.exports = (robot) ->

  cronjob = new cronJob(
    cronTime: "0 55 8 * * *"    # 実行時間
    start:    true                # すぐにcronのjobを実行するか
    timeZone: "Asia/Tokyo"        # タイムゾーン指定
    onTick: ->                    # 時間が来た時に実行する処理
      robot.send {room: "test"}, "cronのテストです"
  )
