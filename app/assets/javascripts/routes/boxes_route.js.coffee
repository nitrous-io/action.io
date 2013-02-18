AIO.BoxesIndexRoute = Em.Route.extend
  setupController: (controller) ->
    #AIO.util.mixpanelIdentifyUser()
    #AIO.util.mixpanel 'Viewed Boxes Index'
    boxesController = controller.get 'controllers.boxes'
    if !boxesController.get('content') || boxesController.get('content').length == 0
      boxesController.set 'content', []
      boxesController.loadAll boxes: AIO.get('preloadedBoxes')
    boxesController.findAll()

AIO.BoxesNewRoute = Em.Route.extend
  setupController: (controller) ->
    #AIO.util.mixpanel 'Viewed New Box'
    controller.newRecord()

AIO.BoxesProvisioningRoute = Em.Route.extend
  # hack because in model we dont have access to controller hence we cannot
  # really lookup for the model instance, so we pass the id back into
  # setupController to look for the model there
  setupController: (controller, params) ->
    # AIO.util.mixpanel 'Viewed Box Provisioning', box_id: context.id
    controller.findById parseInt(params.id, 10)

AIO.IdeRoute = Em.Route.extend
  setupController: (controller, params) ->
    # AIO.util.mixpanel 'IDE Session Started', box_id: context.id
    # AIO.util.mixpanelIncrement 'ide_session_started_count'
    controller.findById parseInt(params.id, 10)
    # warn the user before actually unload the window. This is helpful to
    # prevent mis-click close tab / cmd + w
    $(window).bind 'beforeunload.ide', ->
      "Remember to save all changes before closing the editor"
  deactivate: ->
    $(window).unbind 'beforeunload.ide'
