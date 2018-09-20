# Description:
#   ポルンガ召喚

module.exports = (robot) ->
    robot.hear /(タッカラプト ポッポルンガ プピリット パロ)/i, (msg) ->
#        data =
#          file: fs.createReadStream('../image/porunga.png')
#          channels: msg.envelope.room
#        robot.adapter.client.web.files.upload("ポルンガ！！", data)

        filename = 'image/porunga.png'
        channel = msg.message.rawMessage.channel
        msg.send ("curl -F file=@#{filename} -F channels=#{channel} -F token=#{process.env.HUBOT_SLACK_TOKEN} https://slack.com/api/files.upload")
        exec "curl -F file=@#{filename} -F channels=#{channel} -F token=#{process.env.HUBOT_SLACK_TOKEN} https://slack.com/api/files.upload", (err, stdout, stderr) ->
          if err
            msg.send (stderr)
