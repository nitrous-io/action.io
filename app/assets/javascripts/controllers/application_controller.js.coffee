AIO.ApplicationController = Em.Controller.extend
  currentUser: null

  initialize: (options={}) ->
    if environment = options.environment
      AIO.set 'environment', environment

    if currentUser = options.currentUser
      AIO.set 'currentUser', AIO.User.create(currentUser.user)

    if pusherKey = options.pusherKey
      AIO.get('router.pusherController').initialize pusherKey

    [
      'firebaseHost'
      'n2o128mbMemory'
      'n2o250mbStorage'
    ].forEach (name) ->
      if val = options[name]
        AIO.set name, val
