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
          router.get('boxesController').findAll()
          router.get('applicationController').connectOutlet 'boxesIndex'

      new: Em.Route.extend
        route: '/new'
        connectOutlets: (router) ->
          router.get('boxesNewController').newRecord()
          router.get('applicationController').connectOutlet 'boxesNew'

      provisioning: Em.Route.extend
        route: '/:id/provisioning'
        connectOutlets: (router, context) ->
          controller = router.get 'boxesProvisioningController'
          router.get('boxesController').findResource parseInt(context.id, 10), (resource) ->
            controller.set 'content', resource
          router.get('applicationController').connectOutlet 'boxesProvisioning'
        exit: (router) ->
          router.get('boxesProvisioningController').set 'content', null

      ide: Em.Route.extend
        route: '/:id/ide'
        connectOutlets: (router, context) ->
          controller = router.get 'ideController'
          router.get('boxesController').findResource parseInt(context.id, 10), (resource) ->
            controller.set 'content', resource
          router.get('applicationController').connectOutlet 'ide'
        exit: (router) ->
          router.get('ideController').set 'content', null

    publicKeys: Em.Route.extend
      route: '/public_keys'

      index: Em.Route.extend
        route: '/'
        connectOutlets: (router) ->
          router.get('publicKeysController').findAll()
          router.get('applicationController').connectOutlet 'publicKeysIndex'

      new: Em.Route.extend
        route: '/new'
        connectOutlets: (router) ->
          router.get('publicKeysNewController').newRecord()
          router.get('applicationController').connectOutlet 'publicKeysNew'

