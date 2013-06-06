AIO.ApplicationController = Em.Controller.extend
  currentUser: null

  initialize: (options={}) ->
    if environment = options.environment
      AIO.set 'environment', environment

    if currentUser = options.currentUser
      @set 'currentUser', AIO.User.create currentUser.user

    if pusherKey = options.pusherKey
      AIO.get('router.pusherController').initialize pusherKey

    if firebasehost = options.firebasehost
      aio.set 'firebasehost', firebasehost

    if showIntroScreen = options.showIntroScreen
      console.log showIntroScreen
