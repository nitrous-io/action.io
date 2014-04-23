#= require application
#= require sinon-1.9.1
#= require ember-bootstrap
#= require_tree .
#= require app
#= require_self

App.setupForTesting()
App.injectTestHelpers()

Em.Test.adapter = Em.Test.QUnitAdapter.create()

$ ->
  $('body').append($('<div id="app" style="display:none">'))
