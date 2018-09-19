# Description:
#   Backlog to Slack

backlogUrl = 'https://usn.backlog.com/'

module.exports = (robot) ->
  robot.router.post "/backlog/:room", (req, res) ->
    { room } = req.params
    { body } = req
    try
      switch body.type
        when 1
          msg  = "*Backlog [#{body.project.projectKey}-#{body.content.key_id}] #{body.content.summary} _by #{body.createdUser.name}_*\n"
          msg += "課題が追加されました\n";
          msg += "#{backlogUrl}view/#{body.project.projectKey}-#{body.content.key_id}"
          msg += ">>> #{body.content.comment.content}\n"
        when 2, 3
          msg  = "*Backlog [#{body.project.projectKey}-#{body.content.key_id}] #{body.content.summary} _by #{body.createdUser.name}_*\n"
          msg += "課題が更新されました\n";
          msg += "#{backlogUrl}view/#{body.project.projectKey}-#{body.content.key_id}#comment-#{body.content.comment.id}"
          msg += ">>> #{body.content.comment.content}\n"
        when 5
          msg  = "*Backlog [#{body.project.projectKey}] #{body.content.name} _by #{body.createdUser.name}_*\n"
          msg += "Wikiページが登録されました\n";
          msg += "#{backlogUrl}wiki/#{body.project.projectKey}/#{body.content.name}\n"
          msg += ">>> #{body.content.content}\n"
        when 6
          msg  = "*Backlog [#{body.project.projectKey}] #{body.content.name} _by #{body.createdUser.name}_*\n"
          msg += "Wikiページが更新されました\n";
          msg += "#{backlogUrl}wiki/#{body.project.projectKey}/#{body.content.name}\n"
          msg += ">>> #{body.content.content}\n"
        when 8
          msg  = "*Backlog [#{body.project.projectKey}] #{body.content.dir}#{body.content.name} _by #{body.createdUser.name}_*\n"
          msg += "共有ファイルが追加されました\n";
          msg += "#{backlogUrl}file/#{body.project.projectKey}#{body.content.dir}#{body.content.name}\n";
        when 9
          msg  = "*Backlog [#{body.project.projectKey}] #{body.content.dir}#{body.content.name} _by #{body.createdUser.name}_*\n"
          msg += "共有ファイルが更新されました\n";
          msg += "#{backlogUrl}file/#{body.project.projectKey}#{body.content.dir}#{body.content.name}\n";
        when 12
          ref = body.content.ref.split("/").pop()
          msg  = "*Backlog [#{body.project.projectKey}] #{body.content.revisions[0].comment} _by #{body.createdUser.name}_*\n"
          msg += "GIT リポジトリ#{body.content.repository.name} の #{ref}にプッシュされました\n";
          msg += "#{backlogUrl}git/#{body.project.projectKey}/#{body.content.repository.name}/#{body.content.revision_type}/#{body.content.revisions[0].rev}";
        when 14
          msg  = "*Backlog [#{body.project.projectKey}] 課題をまとめて操作 _by #{body.createdUser.name}_*\n"
          msg += "課題がまとめて更新されました\n";
          msg += ">>> "
          for link in body.content.link
            msg += "[#{body.project.projectKey}-#{link.key_id}] #{link.title}\n"
            msg += "#{backlogUrl}view/#{body.project.projectKey}-#{link.key_id}\n\n"
        else
          # 上記以外はスルー
          return

      # Slack に投稿
      if msg?
        robot.messageRoom room, msg
        res.end "OK"
      else
        robot.messageRoom room, "Backlog integration error."
        res.end "Error"
    catch error
      robot.send
      res.end "Error"
