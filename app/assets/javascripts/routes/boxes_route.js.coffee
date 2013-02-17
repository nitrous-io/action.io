AIO.BoxesIndexRoute = Em.Route.extend
  setupController: (controller) ->
    #AIO.util.mixpanelIdentifyUser()
    #AIO.util.mixpanel 'Viewed Boxes Index'
    unless controller.get('content') 
      controller.set 'content', []
      controller.loadAll boxes: AIO.get('preloadedBoxes')
    controller.findAll()

