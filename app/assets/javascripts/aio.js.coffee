#= require hamlcoffee
#= require backbone
#= require backbone_datalink
#= require backbone-relational
#= require knockout
#= require knockback
#= require json2
#= require_self
#= require_tree ./templates
#= require_tree ./models
#= require_tree ./views
#= require_tree ./view_models
#= require_tree ./routers
#= require_tree ./sockets

window.AIO =
  env: null
  router: null
  currentUser: null

  initialize: (options={}) ->
    @env = options.env

