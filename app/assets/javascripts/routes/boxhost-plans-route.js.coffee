App.BoxhostPlansRoute = Em.Route.extend
  beforeModel: ->
    unless App.get('currentUser.dedicated_allowed')
      @transitionTo 'boxes.index'

  model: ->
    App.get('boxhostPlans')

  setupController: (controller) ->
    @_super.apply this, arguments
    # TODO Set up user's already purchased boxhosts so that we can show her what
    # she already has.

  activate: ->
    App.get('boxhostPlans').reload()
