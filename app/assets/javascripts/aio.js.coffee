#= require_self
#= require_tree ../templates
#= require_tree ./models
#= require_tree ./views
#= require_tree ./routers

window.aio =
  models: {}
  collections: {}
  routers: {}
  views: {}

  app:
    rootRouter: null

    initialize: ->

