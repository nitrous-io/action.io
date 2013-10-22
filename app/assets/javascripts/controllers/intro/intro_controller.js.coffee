AIO.IntroController = Em.Controller.extend
  markIntroSeen: ->
    AIO.set 'currentUser.intro_seen', true
    $.ajax(type: 'PUT', url: '/user/intro_seen')

  quitIntro: ->
    this.markIntroSeen()
    page = 'boxes.index'

    # If a user hasn't created a box, then just go straight to the box new page
    if AIO.get('router.boxesController.content.length') == 0
      page = 'boxes.new'

    AIO.get('router').transitionTo page
