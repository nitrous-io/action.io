#= require_self
#= require_tree ../templates
#= require_tree ./models
#= require_tree ./views
#= require_tree ./helpers
#= require_tree ./routers

window.aio =
  models: {}
  collections: {}
  views: {}
  helpers: {}
  routers: {}

  app:
    rootRouter: null

    initialize: ->

