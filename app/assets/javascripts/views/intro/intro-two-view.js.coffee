App.IntroTwoView = Em.View.extend
  templateName: 'templates/intro/intro-two'
  classNames: ['app_page', 'intro']

  didClickNextScreen: ->
    App.get('router').transitionTo 'introThree'

  didClickPrevScreen: ->
    App.get('router').transitionTo 'introOne'
