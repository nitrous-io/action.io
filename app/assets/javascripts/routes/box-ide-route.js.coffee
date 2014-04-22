#= require ./ide-route

App.BoxIdeRoute = App.IdeRoute.extend
  setupController: (controller) ->
    @_super.apply this, arguments
    controller.initialize()

  deactivate: ->
    @_super()
    @controller.reset()
    @controller.set 'content', null
