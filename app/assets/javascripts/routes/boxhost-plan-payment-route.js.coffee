# 1. Display boxhost plan details.
# 2. Ask for credit card details.
# 3. Upon card detail submission, if there are errors, show them.
# 4. If card is valid, redirect to boxhosts.new.
App.BoxhostPlanPaymentRoute = Em.Route.extend
  beforeModel: ->
    if !App.get('currentUser.dedicated_allowed')
      @transitionTo 'boxes.index'
    else if App.get('currentUser.isDelinquent')
      @transitionTo 'account'

  afterModel: (model) ->
    if App.get('subscription.active')
      @transitionTo 'boxhost_plan.confirm', model
