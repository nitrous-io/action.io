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
  setupController: (controller) ->
    controller.findById parseInt(context.id, 10)

  model: (params) ->
    console.log this
    debugger

