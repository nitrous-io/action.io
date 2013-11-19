AIO.IntroCreateBoxView = AIO.BoxFormView.extend
  templateName: 'templates/intro/intro_create_box'
  elementId: 'intro_create_box_view'
  classNames: ['app_page', 'intro', 'new']

  markIntroSeen: ->
    AIO.set 'currentUser.intro_seen', true
    $.ajax(type: 'PUT', url: '/user/intro_seen')

  didClickNextScreen: ->
    this.markIntroSeen()
    this.didClickCreateBox()

  didClickSkipIntro: ->
    this.markIntroSeen()
    this.didClickCancel()
