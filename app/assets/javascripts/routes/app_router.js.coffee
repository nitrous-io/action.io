AIO.Router = Em.Router.extend
  location: 'hash'

  root: Em.Route.extend
    index: Em.Route.extend
      route: '/'
      redirectsTo: 'boxes.index'

    boxes: Em.Route.extend
      route: '/boxes'

      index: Em.Route.extend
        route: '/'
        connectOutlets: (router) ->
          controller = router.get 'boxesController'
          controller.findAll()
          router.get('applicationController').connectOutlet
            controller: controller
            viewClass: AIO.BoxesIndexView

      new: Em.Route.extend
        route: '/new'
        connectOutlets: (router) ->
          controller = router.get 'boxController'
          controller.newRecord()
          router.get('applicationController').connectOutlet
            controller: controller
            viewClass: AIO.BoxesNewView

      ide: Em.Route.extend
        route: '/:id/ide'
        connectOutlets: (router, context) ->
          controller = router.get 'ideController'
          router.get('boxesController').findResource parseInt(context.id, 10), (resource) ->
            controller.set 'content', resource
          router.get('applicationController').connectOutlet
            controller: controller
            viewClass: AIO.IdeLayoutView

        exit: (router) ->
          router.get('ideController').set 'content', null

    publicKeys: Em.Route.extend
      route: '/public_keys'

      index: Em.Route.extend
        route: '/'
        connectOutlets: (router) ->
          controller = router.get 'publicKeysController'
          controller.findAll()
          router.get('applicationController').connectOutlet
            controller: controller
            viewClass: AIO.PublicKeysIndexView

      new: Em.Route.extend
        route: '/new'
        connectOutlets: (router) ->
          controller = router.get 'publicKeyController'
          controller.newRecord()
          router.get('applicationController').connectOutlet
            controller: controller
            viewClass: AIO.PublicKeysNewView

