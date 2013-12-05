AIO.IntroController = Em.Controller.extend
  quitIntro: ->
    page = 'boxes.index'

    # If a user hasn't created a box, then just go straight to the box new page
    if AIO.get('router.boxesController.content.length') == 0
      page = 'boxes.new'

    AIO.get('router').transitionTo page
