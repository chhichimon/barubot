# Description:
#   wikipedia 検索
#
# Commands:
#   hubot <ワード>って(なに or 何)

apiUrl = "https://ja.wikipedia.org/w/api.php?action=query&format=json&prop=extracts&redirects=1&exchars=500&explaintext=1"

module.exports = (robot) ->
  robot.respond(/(.+)って(なに|何)/i, (msg) ->
    request = robot.http(apiUrl)
      .query(titles: msg.match[1])
      .get()

    request((err, res, body) ->
      if err
        msg.send("なんかエラーが起きました...")
        return

      data = JSON.parse(body)
      for id, value of data.query.pages
        if value.extract?
          respond = "説明しよう！\n"
          respond += value.extract
          msg.send(respond)
        else
          respond = "http://www.google.co.jp/search?q="
          respond += msg.match[1]
          msg.send(respond)
    )
  )
