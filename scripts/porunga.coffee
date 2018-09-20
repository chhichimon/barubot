# Description:
#   ポルンガ召喚

module.exports = (robot) ->
  robot.hear /(タッカラプト ポッポルンガ プピリット パロ)/i, (msg) ->
    fs = require 'fs'
    try
      data =
        file: fs.createReadStream('./porunga.png')
        channels: msg.envelope.room
      robot.adapter.client.web.files.upload("ポルンガ！！", data)

    catch error
      console.log error
