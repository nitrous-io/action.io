#= require "zeroclipboard/ZeroClipboard"
#= require "./zeroclipboard-path"
#= require mousetrap
#= require codemirror
#= require firepad
#= require base64
#= require strftime
#= require jquery.ui.widget
#= require jquery.fileupload
#= require ua-parser
#= require ember-bootstrap
#= require shareable
#= require jquery.payment
#= require gh3
#= require_self
#= require_tree ./mixins
#= require_tree ./lib
#= require_tree ./models
#= require_tree ./view-models
#= require_tree ./controllers
#= require_tree ./views
#= require_tree ./helpers
#= require_tree ./templates
#= require_tree ./routes

window.NitrousIO = Em.Application.extend
  rootElement: '#app'
  online: if !Em.isNone(window.navigator.onLine) then window.navigator.onLine else true
  offline: Em.computed.not 'online'

  boxes: (->
    App.Box.all()
  ).property()

  snapshots: (->
    App.Snapshot.all()
  ).property()

  boxTemplates: (->
    App.BoxTemplate.all()
  ).property()

  regions: (->
    App.Region.all()
  ).property()

  repositories: (->
    App.Repository.all()
  ).property()

window.App = NitrousIO.create()

Em.TextSupport.reopen
  attributeBindings: ['readonly']

# prevent file drops on the document causing browser to navigate away
$(document).bind 'drop dragover', (e) ->
  e.preventDefault()

# prevent esc from disconnecting websocket connection in firefox
$(window).keydown (e) ->
  e.preventDefault() if e.keyCode == 27

$(window).on 'message', (event) ->
  if event.originalEvent.data == "chromeWebView"
    window.App?.set? 'isChromeWebView', true
    $('#install-chrome-app').hide()

$(window).on 'offline', ->
  window.App?.set? 'online', false

$(window).on 'online', ->
  window.App?.set? 'online', true
