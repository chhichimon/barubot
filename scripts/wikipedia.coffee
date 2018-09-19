# Description:
#   wikipedia 検索

request = require('request');

module.exports = (robot) ->
  robot.respond /(おし|教)えて (.*)/i, (msg) ->
    keyword = encodeURIComponent msg.match[1]
    request.get("https://ja.wikipedia.org/w/api.php?action=query&format=json&prop=extracts&redirects=1&exchars=300&explaintext=1&titles=#{keyword}", (err, res, body) ->
    if err or res.statusCode != 200
        return msg.send "なんかエラーが出た。。。"

    data = JSON.parse(body)
    for id, value of data.query.pages
        if value.extract?
          respond = "Wikipediaによりますと！\n"
          respond += value.extract
          msg.send(respond)
        else
          msg.send("わからない！")

)
