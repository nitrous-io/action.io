AIO.BillingProfile = AIO.Resource.extend
  id                    : null
  formatted_card_number : null
  card_type             : null
  subscriptions         : null
  active                : null

  activeSubscription: (->
    subscriptions = @get 'subscriptions'
    activeSubscription = _.find subscriptions, (subscription) ->
      subscription.state == 'active'
  ).property 'subscriptions'

  activeSubscriptionPlan: (->
    if activeSubscription = @get 'activeSubscription'
      AIO.SubscriptionPlan.create activeSubscription.subscription_plan
  ).property 'activeSubscription'

  upgrade: (selectedPlanId, stripeToken, callback) ->
    activeSubscriptionPlan = @get 'activeSubscriptionPlan'
    if activeSubscriptionPlan
      planChanged = selectedPlanId != activeSubscriptionPlan.get('id')
    else
      planChanged = true

    # plan or credit card details not changed,
    # ignore the upgrade
    unless planChanged || stripeToken
      return callback(null)

    $.ajax(
      url: '/subscription'
      type: this._upgradeType()
      data: { plan_id: selectedPlanId, stripe_token: stripeToken }
    ).done( =>
      callback(null)
    ).fail (e) =>
      errors = $.parseJSON e.responseText
      errorMessage = errors.base
      callback errorMessage

  cancel: (callback) ->
    if @get 'activeSubscription'
      $.ajax(
        url: '/subscription'
        type: 'DELETE'
      ).done( =>
        callback(null)
      ).fail (e) =>
        errors = $.parseJSON e.responseText
        errorMessage = errors.base
        callback errorMessage

  _upgradeType: ->
    # if the user has an exisiting billing profile,
    # update it.
    unless !!@get('id')
      type = 'POST'
    else
      type = 'PUT'
