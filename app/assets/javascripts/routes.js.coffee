AIO.Router.map ->
  this.resource "boxes", ->
    this.route 'new'
    this.route 'provisioning', path: '/:box_id/provisioning'
  this.route 'ide', path: 'boxes/:box_id/ide'
  this.resource 'public_keys', ->
    this.route 'new'

AIO.ApplicationRoute = Em.Route.extend
  setupController: (controller) ->
    @store.load AIO.User, AIO.get('user')
    @store.loadMany AIO.Region, AIO.get('preloadedRegions')
    @store.loadMany AIO.BoxTemplate, AIO.get('preloadedBoxTemplates')
    @store.loadMany AIO.Box, AIO.get('preloadedBoxes')
    AIO.set 'currentUser', AIO.User.first()
    @controllerFor('pusher').initialize AIO.get('pusherKey')

AIO.IndexRoute = Em.Route.extend
  redirect: ->
    this.transitionTo 'boxes'

AIO.BoxesIndexRoute = Em.Route.extend
  model: ->
    AIO.Box.find()
  setupController: (controller) ->
    AIO.util.mixpanelIdentifyUser()
    AIO.util.mixpanel 'Viewed Boxes Index'

AIO.BoxesNewRoute = Em.Route.extend
  model: ->
    AIO.Box.createRecord()
  setupController: (controller, model) ->
    AIO.util.mixpanel 'Viewed New Box'
    model.set 'boxTemplate', AIO.BoxTemplate.first()
    model.set 'region', AIO.Region.first()
    controller.set 'regions', AIO.Region.find()
    controller.set 'boxTemplates', AIO.BoxTemplate.find()

AIO.BoxesProvisioningRoute = Em.Route.extend
  model: (params) ->
    AIO.Box.find params.box_id
    #AIO.util.mixpanel 'Viewed Box Provisioning', box_id: params.id

AIO.IdeRoute = Em.Route.extend
  model: (params) ->
    AIO.Box.find params.box_id
  setupController: (controller) ->
    AIO.util.mixpanelIncrement 'ide_session_started_count'
    # warn the user before actually unload the window. This is helpful to
    # prevent mis-click close tab / cmd + w
    $(window).bind 'beforeunload.ide', ->
      "Remember to save all changes before closing the editor"
  exit: ->
    this.controllerFor('ide').reset()
    $(window).unbind 'beforeunload.ide'

AIO.PublicKeysIndexRoute = Em.Route.extend
  model: ->
    AIO.PublicKey.find()
  setupController: (controller) ->
    AIO.util.mixpanel 'Viewed Public Keys Index'

AIO.PublicKeysNewRoute = Em.Route.extend
  model: ->
    AIO.PublicKey.createRecord()
  setupController: (controller) ->
    AIO.util.mixpanel 'Viewed Public Keys New'
