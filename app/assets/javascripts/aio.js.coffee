#= require socket.io
#= require pusher-1.12.1
#= require ember_bootstrap
#= require codemirror
#= require_self
#= require_tree ./mixins
#= require_tree ./lib
#= require_tree ./models
#= require_tree ./controllers
#= require_tree ./views
#= require_tree ./helpers
#= require_tree ./templates
#= require_tree ./routes

window.AIO = Em.Application.create
  rootElement: '#app'

