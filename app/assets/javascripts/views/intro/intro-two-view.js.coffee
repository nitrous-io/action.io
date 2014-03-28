AIO.IntroTwoView = Em.View.extend
  templateName: 'templates/intro/intro_two'
  classNames: ['app_page', 'intro']

  didClickNextScreen: ->
    AIO.get('router').transitionTo 'introThree'

  didClickPrevScreen: ->
    AIO.get('router').transitionTo 'introOne'
