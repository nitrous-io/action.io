#= require hamlcoffee
#= require backbone
#= require backbone_datalink
#= require backbone-relational
#= require knockout
#= require knockback
#= require json2
#= require EventEmitter
#= require codemirror
#= require pusher-1.12.1
#= require_self
#= require_tree ./templates
#= require_tree ./lib
#= require_tree ./models
#= require_tree ./views
#= require view_models/boxes/show/tabbed_view_model
#= require_tree ./view_models
#= require_tree ./controllers
#= require_tree ./routers

window.AIO =
  c: {}
  vm: {}

  initialize: (options={}) ->
    @environment = options.environment

    if options.currentUser
      @currentUser = new AIO.User(options.currentUser)

    if options.pusherKey
      @pusherController = new AIO.PusherController(options.pusherKey)

    @events = new AIO.EventEmitter
    @callbacks = {}

