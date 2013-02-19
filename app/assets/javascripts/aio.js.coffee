#= require socket.io
#= require mousetrap
#= require codemirror
#= require jquery.ui.widget
#= require jquery.fileupload
#= require ua-parser
#= require ember_bootstrap
#= require_self
#= require store
#= require routes
#= require_tree ./mixins
#= require_tree ./lib
#= require ./models/model
#= require_tree ./models
#= require_tree ./controllers
#= require_tree ./views
#= require_tree ./helpers
#= require_tree ./templates

window.AIO = Em.Application.createWithMixins
  rootElement: '#app'
  bootstrap: (options) ->
    @set 'environment', options.environment
    @set 'user', options.currentUser.user
    @set 'pusherKey', options.pusherKey
    @set 'preloadedBoxes', options.boxes
    @set 'preloadedRegions', options.regions
    @set 'preloadedBoxTemplates', options.boxTemplates

  # TODO: remove lookup link once we fully migrated to ember 1.0 and removed
  # old patterns i.e. model can referes to controller
  # https://github.com/emberjs/ember.js/commit/5becdc4467573f80a5c5dbb51d97c6b9239714a8
  lookup: (name) ->
    AIO.__container__.lookup(name)

# prevent file drops on the document causing browser to navigate away
$(document).bind 'drop dragover', (e) ->
  e.preventDefault()

