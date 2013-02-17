AIO.ApplicationRoute = Em.Route.extend
  setupController: (controller) ->
    regionsController = controller.get 'controllers.regions'
    if regionsController.get('content') && regionsController.get('content').length == 0
      regionsController.set 'content', []
      regionsController.loadAll regions: AIO.get('preloadedRegions')

    boxTemplatesController = controller.get 'controllers.boxTemplates'
    if boxTemplatesController.get('content') && boxTemplatesController.get('content').length == 0
      boxTemplatesController.set 'content', []
      boxTemplatesController.loadAll box_templates: AIO.get('preloadedBoxTemplates')
