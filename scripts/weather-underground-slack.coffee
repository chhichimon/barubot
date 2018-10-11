# Description:
#   Backlog to Slack

module.exports = (robot) ->
  robot.router.post "/weather", (req, res) ->
    body = req.body

    conditions = []
    conditions = [
      {
        en: "Sunny"
        ja: "晴れ"
      },
      {
        en: "Mostly Clear"
        ja: "快晴"
      },
      {
        en: "Mostly Sunny"
        ja: "快晴"
      },
      {
        en: "Rain"
        ja: "雨"
      },
      {
        en: "Showers"
        ja: "にわか雨"
      },
      {
        en: "Snow"
        ja: "雪"
      },
      {
        en: "Cloudy"
        ja: "曇り"
      },
      {
        en: "Mostly Cloudy"
        ja: "曇りのち晴れ"
      },
      {
        en: "Partly Cloudy"
        ja: "晴れ時々曇り"
      },
      {
        en: "Scattered Thunderstorms"
        ja: "広い範囲で雷雨"
      }
    ]

    condition_ja = get_condition_ja(body.condition,conditions)
    condition_ja = body.condition if condition_ja == ""

    # メッセージ整形
    data =
      attachments: [
        color: "#07b3de"
        thumb_url: "#{body.image_url}"
        title: "今日の天気 - 台東区"
        title_link: "#{body.forecast_url}"
        text: "#{condition_ja}\n" + "最高気温：#{body.high_temp}℃\n" + "最低気温：#{body.low_temp}℃\n" + "湿度：#{body.humidity}%\n" + "\n#{body.check_time}"
      ]

    # Slack に投稿
    robot.messageRoom "talk", data
    res.end "OK"

# コンディション変換
get_condition_ja = (condition_en , condition_list) ->
  return "" if condition_list == null

  for condition in condition_list
    return condition.ja if condition.en == condition_en
  return ""
