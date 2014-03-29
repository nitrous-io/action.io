App.IntroFourView = Em.View.extend
  templateName: 'templates/intro/intro-four'
  classNames: ['app_page', 'intro']

  # TODO: Add flash message with link to getn2o page
  didClickNextScreen: ->
    App.get('router').transitionTo 'introFive'

  didClickPrevScreen: ->
    App.get('router').transitionTo 'introThree'
