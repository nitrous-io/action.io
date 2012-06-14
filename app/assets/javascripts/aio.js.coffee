#= require hamlcoffee
#= require backbone
#= require backbone_datalink
#= require backbone-relational
#= require knockout
#= require knockback
#= require json2
#= require_self
#= require_tree ./templates
#= require_tree ./lib
#= require_tree ./models
#= require_tree ./views
#= require_tree ./view_models
#= require_tree ./routers

window.AIO =
  env: null
  router: null
  currentUser: null
  c: {}
  vm: {}

  initialize: (options={}) ->
    @env = options.env

    if options.currentUser
      @currentUser = new AIO.User(options.currentUser)

