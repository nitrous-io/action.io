AIO.PublicKeysIndexRoute = Em.Route.extend
  setupController: (controller) ->
    #AIO.util.mixpanel 'Viewed Public Keys Index'
    if !controller.get('content')
      controller.set 'content', []
    publicKeysController = controller.get('controllers.publicKeys')
    publicKeysController.findAll()

AIO.PublicKeysNewRoute = Em.Route.extend
  setupController: (controller) ->
    #AIO.util.mixpanel 'Viewed Public Keys New'
    controller.newRecord()

