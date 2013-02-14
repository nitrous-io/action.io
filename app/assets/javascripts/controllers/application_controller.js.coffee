AIO.ApplicationController = Em.Controller.extend
  currentUser: null

  initialize: (options={}) ->
    if environment = options.environment
      AIO.set 'environment', environment

    if backendDisabled = options.backendDisabled
      AIO.set 'backendDisabled', backendDisabled

    if currentUser = options.currentUser
      @set 'currentUser', AIO.User.create currentUser.user

    if pusherKey = options.pusherKey
      AIO.get('router.pusherController').initialize pusherKey

