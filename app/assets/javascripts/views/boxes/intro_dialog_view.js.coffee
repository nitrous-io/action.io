AIO.IntroDialogView = AIO.IdeModalDialogView.extend
  templateName: 'templates/intro/main'
  elementId: 'intro_dialog_view'
  contentBinding: 'controller.introDialog' # BoxesIndexController

  didClickDone: ->
    @get('controller').hideIntro()
    content = @get 'content'
    if user = content.user
      user.endIntro()

  didClickInviteFriends: ->
    @get('controller').hideIntro()
    Em.run.scheduleOnce 'afterRender', this, ->
      AIO.get('router').transitionTo 'invites.index'
