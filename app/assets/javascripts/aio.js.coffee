#= require socket.io
#= require mousetrap
#= require codemirror
#= require jquery.ui.widget
#= require jquery.fileupload
#= require ua-parser
#= require ember_bootstrap
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

# prevent file drops on the document causing browser to navigate away
$(document).bind 'drop dragover', (e) ->
  e.preventDefault()
