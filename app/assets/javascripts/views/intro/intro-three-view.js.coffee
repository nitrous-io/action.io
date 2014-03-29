App.IntroThreeView = Em.View.extend
  templateName: 'templates/intro/intro-three'
  classNames: ['app_page', 'intro']

  didClickNextScreen: ->
    App.get('router').transitionTo 'introFour'

  didClickPrevScreen: ->
    App.get('router').transitionTo 'introTwo'
