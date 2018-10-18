# Description:
#  Manage backlog

request = require "request"
req_async = require "async"


class Backlog
  backlogApiKey = process.env.BACKLOG_API_KEY
  backlogApiDomain = "https://usn.backlog.com"
  backlogDomain = "https://usn.backlog.com/"

  getUsers: () ->
    new Promise (resolve) ->
      url = "#{backlogApiDomain}/api/v2/users?apiKey=#{backlogApiKey}"
      options =
        url: url
      request options, (err, res, body) ->
        json = JSON.parse body
        messages = []
        for row in json
          messages.push("#{row.id} : #{row.name}")
        resolve messages

  getUser: (name) ->
    new Promise (resolve) ->
      url = "#{backlogApiDomain}/api/v2/users?apiKey=#{backlogApiKey}"
      options =
        url: url
      request options, (err, res, body) ->
        json = JSON.parse body
        for row in json
          if row.name == name
            resolve row.id

  getIssues: (params) ->
    new Promise (resolve) ->
      url = "#{backlogApiDomain}/api/v2/issues?apiKey=#{backlogApiKey}"
      options =
        url: url
        qs: params

      request options, (err, res, body) ->
        json = JSON.parse body
        messages = []
        for param in json
          messages.push("<#{backlogDomain}/view/#{param.issueKey}|#{param.summary}>")

        resolve messages

  # Backlogから課題情報を取得
  get_issue: (issue_id_or_key,callback) ->
    url = "#{backlogApiDomain}/api/v2/issues/#{issue_id_or_key}"
    options =
      url: url
      qs: {
        apiKey: backlogApiKey
      }

    request.get options, (err,res,body) ->
      if err? or res.statusCode isnt 200
        console.log err
        return
      else
        callback(err,res,body)

  get_issues: (params,callback) ->
    url = "#{backlogApiDomain}/api/v2/issues?apiKey=#{backlogApiKey}"
    options =
      url: url
      qs: params

    request.get options, (err, res, body) ->
      if err? or res.statusCode isnt 200
        console.log err
        return
      else
        issues_info = JSON.parse body
        messages = []
        req_async.map issues_info
        , (issue,callback) ->
          message = "<#{backlogDomain}/view/#{issue.issueKey}|#{issue.summary}>"
          messages.push message
          callback(null,message)
        , (err,result) ->
          callback(err,res,messages)

  # since,until (yyyy-MM-dd)
  get_stars: (user_id,since_str,until_str,callback) ->
    url = "#{backlogApiDomain}/api/v2/users/#{user_id}/stars/count?apiKey=#{backlogApiKey}"
    options =
      url: url
      qs: {
        apiKey: backlogApiKey
        since: since_str
        until: until_str
      }
    request options, (err, res, body) ->
      if err? or res.statusCode isnt 200
        console.log err
        return
      else
        result = JSON.parse body
        callback(err,res,result.count)

module.exports = Backlog
