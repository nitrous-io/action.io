#= require "zeroclipboard/ZeroClipboard"
#= require "./zeroclipboard_path"
#= require mousetrap
#= require codemirror
#= require firepad
#= require base64
#= require jquery.ui.widget
#= require jquery.fileupload
#= require ua-parser
#= require ember_bootstrap
#= require shareable
#= require jquery.payment
#= require_self
#= require_tree ./mixins
#= require_tree ./lib
#= require_tree ./models
#= require_tree ./view_models
#= require_tree ./controllers
#= require_tree ./views
#= require_tree ./helpers
#= require_tree ./templates
#= require_tree ./routes

window.NitrousIO = Em.Application.extend
  rootElement: '#app'
  online: if !Em.isNone(window.navigator.onLine) then window.navigator.onLine else true
  offline: Em.computed.not 'online'

window.AIO = NitrousIO.create()

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
    window.AIO?.set? 'isChromeWebView', true
    $('#install-chrome-app').hide()

$(window).on 'offline', ->
  window.AIO?.set? 'online', false

$(window).on 'online', ->
  window.AIO?.set? 'online', true
