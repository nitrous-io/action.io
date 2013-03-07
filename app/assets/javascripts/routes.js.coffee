# We user this format `boxesIndex` when refering to a controller in
# `#controllerFor` to conform with the bindings we used controllers
# https://github.com/emberjs/ember.js/issues/2000
AIO.Router.map ->
  this.resource "boxes", ->
    this.route 'new'
    this.route 'provisioning', path: '/:id/provisioning'
  this.route 'ide', path: '/boxes/:id/ide'
  this.resource 'public_keys', ->
    this.route 'new'

AIO.Route = Em.Route.extend
  # hack so we can built up correct url params and also passed correct params
  # { id: some_id } into setupController. Otherwise, Ember will just return
  # either a model ar a hash with only ids depends on whether we do a
  # transitionTo or load the url manually. This can be by making the `model`
  # hook return a promised like object, then serialize/deserialize will behave
  # properly i.e. wait for the promise to resolve.
  #
  # Check `route.js` and `router.js` for more info.
  serialize: (model, params) ->
    { id: model.get('id') } if params[0] == "id"

AIO.IndexRoute = AIO.Route.extend
  redirect: ->
    this.transitionTo 'boxes'

AIO.BoxesIndexRoute = AIO.Route.extend
  model: ->
    @controllerFor('boxesIndex').get('content')
  setupController: (controller) ->
    controller.findAll()
    AIO.util.mixpanelIdentifyUser()
    AIO.util.mixpanel 'Viewed Boxes Index'

AIO.BoxesNewRoute = AIO.Route.extend
  model: ->
    box = AIO.Box.create()
    box.set 'box_template_id', @controllerFor('boxTemplates').get('firstObject.id')
    box
  setupController: (controller) ->
    AIO.util.mixpanel 'Viewed New Box'

AIO.BoxesProvisioningRoute = AIO.Route.extend
  setupController: (controller, params) ->
    box_id = parseInt params.id, 10
    AIO.util.mixpanel 'Viewed Box Provisioning', box_id: box_id
    @controllerFor('boxesIndex').findResource box_id, (box) ->
      controller.set 'content', box
  deactivate: ->
    @controllerFor('boxesProvisioning').set 'content', null

AIO.IdeRoute = AIO.Route.extend
  setupController: (controller, params) ->
    box_id = parseInt params.id, 10
    AIO.util.mixpanel 'IDE Session Started', box_id: box_id
    AIO.util.mixpanelIncrement 'ide_session_started_count'
    @controllerFor('boxesIndex').findResource box_id, (box) ->
      controller.set 'content', box
    # warn the user before actually unload the window. This is helpful to
    # prevent mis-click close tab / cmd + w
    $(window).bind 'beforeunload.ide', ->
      "Remember to save all changes before closing the editor"
  deactivate: ->
    @controllerFor('ide').reset()
    $(window).unbind 'beforeunload.ide'

AIO.PublicKeysIndexRoute = AIO.Route.extend
  model: ->
    @controllerFor('publicKeysIndex').get('content')
  setupController: (controller) ->
    @controllerFor('publicKeysIndex').findAll()
    AIO.util.mixpanel 'Viewed Public Keys Index'

AIO.PublicKeysNewRoute = AIO.Route.extend
  model: ->
    AIO.PublicKey.create()
  setupController: (controller) ->
    AIO.util.mixpanel 'Viewed Public Keys New'
