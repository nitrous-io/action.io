#= require socket.io
#= require mousetrap
#= require codemirror
#= require jquery.ui.widget
#= require jquery.fileupload
#= require ua-parser
#= require ember_bootstrap
#= require_self
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
    @set 'currentUser', AIO.User.create().deserialize(options.currentUser.user)
    this.lookup('controller:regions').loadAll regions: options.regions
    this.lookup('controller:boxTemplates').loadAll box_templates: options.boxTemplates
    this.lookup('controller:boxesIndex').loadAll boxes: options.boxes
    this.lookup('controller:pusher').initialize options.pusherKey

  ready: ->
    if @get('environment') == 'development'
      Em.LOG_BINDINGS = true
      AIO.LOG_TRANSITIONS = true

  # TODO: remove lookup link once we fully migrated to ember 1.0 and removed
  # old patterns i.e. model can referes to controller
  # https://github.com/emberjs/ember.js/commit/5becdc4467573f80a5c5dbb51d97c6b9239714a8
  lookup: (name) ->
    AIO.__container__.lookup(name)

# prevent file drops on the document causing browser to navigate away
$(document).bind 'drop dragover', (e) ->
  e.preventDefault()
