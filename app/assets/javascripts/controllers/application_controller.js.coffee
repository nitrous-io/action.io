AIO.ApplicationController = Em.Controller.extend
  currentUser: null

  initialize: (options={}) ->
    @set 'environment', options.environment

    if options.currentUser
      @set 'currentUser', AIO.User.create(options.currentUser.user)

