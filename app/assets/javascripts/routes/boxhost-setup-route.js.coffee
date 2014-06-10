App.BoxhostSetupRoute = Em.Route.extend
  beforeModel: ->
    unless App.get('currentUser.dedicated_allowed')
      @transitionTo 'boxes.index'

  afterModel: (model) ->
    if !model.get('unprovisioned')
      @transitionTo 'boxes.index'
