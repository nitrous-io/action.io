App.IntroOneView = Em.View.extend
  templateName: 'templates/intro/intro-one'
  classNames: ['app_page', 'intro']

  didClickNextScreen: ->
    App.get('router').transitionTo 'introTwo'

  didClickSkipIntro: ->
    @get('controller').quitIntro()
