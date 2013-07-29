AIO.IntroController = Em.Controller.extend
  markIntroSeen: ->
    AIO.set 'currentUser.intro_seen', true
    $.ajax(type: 'PUT', url: AIO.buildResourceUrl('/user/intro_seen'))

  quitIntro: ->
    this.markIntroSeen()
    AIO.get('router').transitionTo 'boxes.index'
