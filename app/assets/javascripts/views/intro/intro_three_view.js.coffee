AIO.IntroThreeView = Em.View.extend
  templateName: 'templates/intro/intro_three'
  classNames: ['app_page', 'intro']

  didClickNextScreen: ->
    AIO.get('router').transitionTo 'introFour'

  didClickPrevScreen: ->
    AIO.get('router').transitionTo 'introTwo'
