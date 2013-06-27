AIO.IntroOneView = Em.View.extend
  templateName: 'templates/intro/intro_one'
  classNames: ['app_page', 'intro']

  didClickNextScreen: ->
    AIO.get('router').transitionTo 'introTwo'

  didClickSkipIntro: ->
    @get('controller').quitIntro()
