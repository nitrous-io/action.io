AIO.BillingProfile = AIO.Resource.extend
  id                    : null
  formatted_card_number : null
  card_type             : null
  subscriptions         : null

  exists: (->
    !!@get('id')
  ).property 'id'

  activeSubscription: (->
    subscriptions = @get 'subscriptions'
    activeSubscription = _.find subscriptions, (subscription) ->
      subscription.state == 'active'
  ).property 'subscriptions'

  activeSubscriptionPlan: (->
    if activeSubscription = @get 'activeSubscription'
      activeSubscription.subscription_plan
  ).property 'activeSubscription'

  upgrade: (selectedPlan, stripeToken, callback) ->
    activeSubscriptionPlan = @get 'activeSubscriptionPlan'
    if activeSubscriptionPlan
      planChanged = (selectedPlan != activeSubscriptionPlan.id)
    else
      planChanged = true

    # plan or credit card details not changed,
    # ignore the upgrade
    unless planChanged || stripeToken
      return callback(null)

    $.ajax(
      url: '/subscription'
      type: this._upgradeType()
      data: { plan_id: selectedPlan, stripe_token: stripeToken }
    ).done((json) =>
      callback(null)
    ).fail (e) =>
      errors = $.parseJSON e.responseText
      errorMessage = errors.base
      callback errorMessage

  _upgradeType: ->
    unless @get 'exists'
      type = 'POST'
    else
      type = 'PUT'
