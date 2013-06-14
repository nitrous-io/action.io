AIO.IntroFiveView = Em.View.extend
  templateName: 'templates/intro/intro_five'
  classNames: ['app_page', 'intro']

  # TODO: Add flash message with link to getn2o page
  didClickDone: ->
    AIO.get('router').transitionTo 'boxes.index'

  didClickPrevScreen: ->
    AIO.get('router').transitionTo 'introFour'
