App.IntroFiveView = Em.View.extend
  templateName: 'templates/intro/intro-five'
  classNames: ['app_page', 'intro']

  # TODO: Add flash message with link to getn2o page
  didClickDone: ->
    @get('controller').quitIntro()

  didClickPrevScreen: ->
    App.get('router').transitionTo 'introFour'
