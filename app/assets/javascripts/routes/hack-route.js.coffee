App.HackRoute = Em.Route.extend
  activate: ->
    App.util.saveReturnTo('hack')

  setupController: (controller) ->
    controller.newRecord()
