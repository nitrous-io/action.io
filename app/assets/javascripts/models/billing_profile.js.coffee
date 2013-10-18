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

  upgrade: (selectedPlanId, stripeToken, couponCode, callback) ->
    # if plan or credit card details are not changed,
    # ignore the upgrade.
    unless stripeToken || this._isPlanChanged(selectedPlanId)
      return callback(null)

    $.ajax(
      url: '/subscription'
      type: this._upgradeType()
      data: { plan_id: selectedPlanId, coupon_code: couponCode, stripe_token: stripeToken }
    ).done( =>
      callback(null)
    ).fail (e) =>
      response = $.parseJSON e.responseText
      errorMessage = response.errors?.base?[0]
      callback errorMessage

  cancel: (callback) ->
    if @get 'activeSubscription'
      $.ajax(
        url: '/subscription'
        type: 'DELETE'
      ).done( =>
        callback(null)
      ).fail (e) =>
        response = $.parseJSON e.responseText
        errorMessage = response.errors?.base?[0]
        callback errorMessage

  _isPlanChanged: (planId) ->
    activeSubscriptionPlan = @get 'activeSubscriptionPlan'
    return true unless activeSubscriptionPlan
    return planId != activeSubscriptionPlan.get('id')

  _upgradeType: ->
    # if the user has an exisiting billing profile,
    # update it.
    if @get('id')
      'PUT'
    else
      'POST'
