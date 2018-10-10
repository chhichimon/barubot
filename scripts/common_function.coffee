# Description:
#   共通関数
#

class common_function


  # 日付をフォーマットする date , format
  date_format : (date, format = 'YYYY-MM-DD hh:mm:ss.SSS',callback) ->

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

    callback(format)

  # 日付を加算する date , num , interval
  date_add : (date, num, interval,callback) ->
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

    callback(date)




  # 2つの日付の差を計算する date1 , date2 ,interval
  date_diff: (date1, date2, interval) ->
    diff = date2.getTime() - date1.getTime()
    new Promise (resolve) ->
      switch interval
        when 'YYYY'
          d1 = new Date date1.getTime()
          d2 = new Date date2.getTime()
          d1.setYear 0
          d2.setYear 0
          if diff >= 0
            i = d2.getTime() < d1.getTime() ? -1 : 0
          else
            i = d2.getTime() <= d1.getTime() ? 0 : 1
          resolve date2.getYear() - date1.getYear() + i
        when 'MM'
          d1 = new Date date1.getTime()
          d2 = new Date date2.getTime()
          d1.setYear 0
          d1.setMonth 0
          d2.setYear 0
          d2.setMonth 0
          if diff >= 0
            i = d2.getTime() < d1.getTime() ? -1 : 0
          else
            i = d2.getTime() <= d1.getTime() ? 0 : 1
          resolve ((date2.getYear() * 12) + date2.getMonth()) - ((date1.getYear() * 12) + date1.getMonth()) + i;
        when 'hh'
          resolve ~~(diff / (60 * 60 * 1000))
        when 'mm'
          resolve ~~(diff / (60 * 1000))
        when 'ss'
          resolve ~~(diff / 1000)
        else
          resolve ~~(diff / (24 * 60 * 60 * 1000))

module.exports = common_function
