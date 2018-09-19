# Description:
#   ポルンガ召喚

module.exports = (robot) ->
    robot.hear /(タッカラプト ポッポルンガ プピリット パロ)/i, (msg) ->
        filename = '../image/porunga.png'
        room = msg.message.room
        exec "curl -F file=@#{filename} -F channels=#{room} -F token=#{process.env.HUBOT_SLACK_TOKEN} https://slack.com/api/files.upload", (err, stdout, stderr) ->
