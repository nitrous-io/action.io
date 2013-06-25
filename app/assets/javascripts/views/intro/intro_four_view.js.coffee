AIO.IntroFourView = Em.View.extend
  templateName: 'templates/intro/intro_four'
  classNames: ['app_page', 'intro']

  # TODO: Add flash message with link to getn2o page
  didClickNextScreen: ->
    AIO.get('router').transitionTo 'introFive'

  didClickPrevScreen: ->
    AIO.get('router').transitionTo 'introThree'
