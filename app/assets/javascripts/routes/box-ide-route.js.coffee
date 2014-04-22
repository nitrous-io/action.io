App.BoxIdeRoute = Em.Route.extend
  activate: ->
    # warn the user before actually unload the window. This is helpful to
    # prevent mis-click close tab / cmd + w
    $(window).bind 'beforeunload.ide', ->
      "Remember to save all changes before closing the editor"

  setupController: (controller) ->
    @_super.apply this, arguments
    controller.initialize()

  deactivate: ->
    $(window).unbind 'beforeunload.ide'
    @controller.reset()
    @controller.set 'content', null
