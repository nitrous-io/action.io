AIO.Router.map ->
  @resource "boxes", ->
    @route 'new'

AIO.IndexRoute = Em.Route.extend
  redirect: -> @transitionTo 'boxes'

AIO.BoxesIndexRoute = Em.Route.extend
  model: -> # do nothing
  setupController: (controller) ->
    #AIO.util.mixpanelIdentifyUser()
    #AIO.util.mixpanel 'Viewed Boxes Index'
    @controllerFor('boxes').findAll()
    controller.set 'content', @controllerFor('boxes')

#AIO.Router = Em.Router.extend
#  location: 'hash'

#  root: Em.Route.extend
#    index: Em.Route.extend
#      route: '/'
#      redirectsTo: 'boxes.index'

#    boxes: Em.Route.extend
#      route: '/boxes'

#      index: Em.Route.extend
#        route: '/'
#        connectOutlets: (router) ->
#          AIO.util.mixpanelIdentifyUser()
#          AIO.util.mixpanel 'Viewed Boxes Index'
#          router.get('boxesController').findAll()
#          router.get('applicationController').connectOutlet 'boxesIndex'

#      new: Em.Route.extend
#        route: '/new'
#        connectOutlets: (router) ->
#          AIO.util.mixpanel 'Viewed New Box'
#          router.get('boxesNewController').newRecord()
#          router.get('applicationController').connectOutlet 'boxesNew'

#      provisioning: Em.Route.extend
#        route: '/:id/provisioning'
#        connectOutlets: (router, context) ->
#          AIO.util.mixpanel 'Viewed Box Provisioning', box_id: context.id
#          controller = router.get 'boxesProvisioningController'
#          router.get('boxesController').findResource parseInt(context.id, 10), (resource) ->
#            controller.set 'content', resource
#          router.get('applicationController').connectOutlet 'boxesProvisioning'
#        exit: (router) ->
#          router.get('boxesProvisioningController').set 'content', null

#      ide: Em.Route.extend
#        route: '/:id/ide'
#        connectOutlets: (router, context) ->
#          AIO.util.mixpanel 'IDE Session Started', box_id: context.id
#          AIO.util.mixpanelIncrement 'ide_session_started_count'

#          controller = router.get 'ideController'
#          router.get('boxesController').findResource parseInt(context.id, 10), (resource) ->
#            controller.set 'content', resource
#          router.get('applicationController').connectOutlet 'ide'
#        enter: (router) ->
#          # warn the user before actually unload the window. This is helpful to
#          # prevent mis-click close tab / cmd + w
#          $(window).bind 'beforeunload.ide', ->
#            "Remember to save all changes before closing the editor"
#        exit: (router) ->
#          $(window).unbind 'beforeunload.ide'
#          router.get('ideController').reset()

#    publicKeys: Em.Route.extend
#      route: '/public_keys'

#      index: Em.Route.extend
#        route: '/'
#        connectOutlets: (router) ->
#          AIO.util.mixpanel 'Viewed Public Keys Index'
#          router.get('publicKeysController').findAll()
#          router.get('applicationController').connectOutlet 'publicKeysIndex'

#      new: Em.Route.extend
#        route: '/new'
#        connectOutlets: (router) ->
#          AIO.util.mixpanel 'Viewed Public Keys New'
#          router.get('publicKeysNewController').newRecord()
#          router.get('applicationController').connectOutlet 'publicKeysNew'

#    vagrant: Em.Route.extend
#      route: '/vagrant'

#      index: Em.Route.extend
#        route: '/'
#        connectOutlets: (router) ->
#          AIO.util.mixpanel 'Viewed Vagrant Settings Page'
#          router.get('vagrantIndexController').reset()
#          router.get('applicationController').connectOutlet 'vagrantIndex'

