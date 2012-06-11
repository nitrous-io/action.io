#= require_self
#= require_tree ../templates
#= require_tree ./models
#= require_tree ./views
#= require_tree ./helpers
#= require_tree ./routers
#= require_tree ./sockets

window.aio =
  models: {}
  collections: {}
  views: {}
  helpers: {}
  routers: {}
  sockets: {}

  app:
    rootRouter: null

    initialize: (options={}) ->
      @environment = options.environment

      if options.currentUser
        @currentUser = new aio.models.User(options.currentUser)

      if options.pusherKey
        @pusher = new Pusher(options.pusherKey)
        if @environment == 'development'
          Pusher.log = (message) -> # Enable pusher logging
            console.log(message)
          WEB_SOCKET_DEBUG = true  # Flash fallback logging

