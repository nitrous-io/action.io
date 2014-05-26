App.BoxhostsPendingRoute = Em.Route.extend
  beforeModel: ->
    unless App.get('currentUser.dedicated_allowed')
      @transitionTo 'boxes.index'

  model: ->
    App.get('boxhosts')

  afterModel: (model) ->
    unprovisioned = model.filter (boxhost) ->
      boxhost.get('unprovisioned')
    if unprovisioned.length == 1
      @transitionTo 'boxhost.setup', unprovisioned.get('firstObject')

  activate: ->
    App.get('boxhosts').reload()
