AIO.Router.map ->
  @resource "boxes", ->
    @route 'new', path: '/new'
    @route 'provisioning', path: '/:id/provisioning'
  @route 'ide', path: '/boxes/:id/ide'
  @resource 'public_keys', ->
    @route 'new', path: '/new'

AIO.Route = Em.Route.extend
  # so we can built up correct url params and also passed correct params
  # { id: some_id } into setupController. Otherwise, Ember will just return
  # either a model or a hash with only ids depends on whether we do a
  # transitionTo or load the url manually.
  # Check `route.js` and `router.js` for more info.
  #
  # So with route /:id/provisioning, we can use:
  #   # with record as an actual Box object
  #   @transitionToRoute 'boxes.provisioning', record
  serialize: (model, params) ->
    { id: model.get('id') } if params[0] == "id"

AIO.IndexRoute = AIO.Route.extend
  redirect: -> @transitionTo 'boxes'

AIO.BoxesIndexRoute = AIO.Route.extend
  setupController: (controller) ->
    #AIO.util.mixpanelIdentifyUser()
    #AIO.util.mixpanel 'Viewed Boxes Index'
    boxes = @controllerFor('boxes')
    boxes.findAll()
    controller.set 'content', boxes

AIO.BoxesNewRoute = AIO.Route.extend
  setupController: (controller) ->
    #AIO.util.mixpanel 'Viewed New Box'
    controller.newRecord()

AIO.BoxesProvisioningRoute = AIO.Route.extend
  setupController: (controller, params) ->
    box_id = parseInt params.id, 10
    #AIO.util.mixpanel 'Viewed Box Provisioning', box_id: box_id
    @controllerFor('boxes').findResource box_id, (box) ->
      controller.set 'content', box
  deactivate: ->
    @controllerFor('boxesProvisioning').set 'content', null

AIO.IdeRoute = AIO.Route.extend
  setupController: (controller, params) ->
    box_id = parseInt params.id, 10
    AIO.util.mixpanel 'IDE Session Started', box_id: box_id
    AIO.util.mixpanelIncrement 'ide_session_started_count'
    @controllerFor('boxes').findResource box_id, (box) ->
      controller.set 'content', box
    # warn the user before actually unload the window. This is helpful to
    # prevent mis-click close tab / cmd + w
    $(window).bind 'beforeunload.ide', ->
      "Remember to save all changes before closing the editor"

  deactivate: ->
    @controllerFor('ide').reset()
    $(window).unbind 'beforeunload.ide'


AIO.PublicKeysIndexRoute = AIO.Route.extend
  setupController: (controller) ->
    publicKeys = @controllerFor('publicKeys')
    publicKeys.findAll()
    controller.set 'content', publicKeys
    AIO.util.mixpanel 'Viewed Public Keys Index'

AIO.PublicKeysNewRoute = AIO.Route.extend
  setupController: (controller) ->
    controller.newRecord()
    AIO.util.mixpanel 'Viewed Public Keys New'

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

