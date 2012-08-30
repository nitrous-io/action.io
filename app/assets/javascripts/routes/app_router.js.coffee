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
          router.get('applicationController').connectOutlet 'boxes'

    publicKeys: Em.Route.extend
      route: '/public_keys'

      index: Em.Route.extend
        route: '/'
        connectOutlets: (router) ->
          controller = router.get 'publicKeysIndexController'
          controller.findAll()
          router.get('applicationController').connectOutlet 'publicKeysIndex'

      new: Em.Route.extend
        route: '/new'
        connectOutlets: (router) ->
          controller = router.get 'publicKeyController'
          controller.newRecord()
          router.get('applicationController').connectOutlet
            controller: controller
            viewClass: AIO.PublicKeysNewView

