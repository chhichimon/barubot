# Description:
#  Manage backlog

request = require "request"
req_async = require "async"
project_list = require('../config/backlog_project_list.json')
req_cmn_fn = require "./common_function"

cmn_fn = new req_cmn_fn()

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

  get_issues_count: (params,callback) ->
    url = "#{backlogApiDomain}/api/v2/issues/count?apiKey=#{backlogApiKey}"
    options =
      url: url
      qs: params

    request.get options, (err, res, body) ->
      if err? or res.statusCode isnt 200
        console.log err
        return
      else
        issues_info = JSON.parse body
        callback(err,res,issues_info.count)


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


  # プロジェクト毎の残課題件数を取得し、レポートメッセージを生成する
  get_backlog_report_message : (project_info,callback) ->
    message_text = ""
    projectId =[]
    project_name = ""

    unless project_info?
      project_name = "全プロジェクト"
    else
      projectId.push project_info.id
      project_name = project_info.name

    today_str = ""
    yesterday_str = ""

    countlist =
      not_started: 0
      processing: 0
      processed: 0
      expired: 0
      today_period: 0
      incomplete: 0


    cmn_fn.date_format new Date(),'YYYY-MM-DD',(due_date_str) ->
      today_str = due_date_str

      cmn_fn.date_add new Date(), -1, 'DD', (due_date) ->
        cmn_fn.date_format due_date,'YYYY-MM-DD',(due_date_str) ->
          yesterday_str = due_date_str

          # 未着手件数
          param =
            projectId: projectId
            statusId: ["1"]
          Backlog.get_issues_count param , (err,res,issues_count) ->
            countlist.not_started = issues_count
            # 処理中件数
            param =
              projectId: projectId
              statusId: ["2"]
            Backlog.get_issues_count param , (err,res,issues_count) ->
              countlist.processing = issues_count
              # 処理済み件数
              param =
                projectId: projectId
                statusId: ["3"]
              Backlog.get_issues_count param , (err,res,issues_count) ->
                countlist.processed = issues_count
                # 期限オーバー件数
                param =
                  projectId: projectId
                  statusId: ["1", "2", "3"]
                  dueDateUntil: yesterday_str
                Backlog.get_issues_count param, (err,res,issues_count) ->
                  countlist.expired = issues_count
                  # 本日期限件数
                  param =
                    projectId: projectId
                    statusId: ["1", "2", "3"]
                    dueDateSince: today_str
                    dueDateUntil: today_str
                  Backlog.get_issues_count param, (err,res,issues_count) ->
                    countlist.today_period = issues_count
                    # 未完了件数
                    countlist.incomplete = countlist.not_started + countlist.processing + countlist.processed

                    # メッセージ整形
                    message_text += ">#{project_name}\n"
                    message_text += "```\n"
                    message_text += "未完了 #{countlist.incomplete}件 ： □ 未着手 #{countlist.not_started}件\t■ 処理中 #{countlist.processing}件\t■ 処理済み #{countlist.processed}件\n本日期限 #{countlist.today_period}件\t期限オーバー #{countlist.expired}件\n"
                    message_text += "```\n"

                    callback(err,res,message_text)


module.exports = Backlog
