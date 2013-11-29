AIO.BillingProfile = AIO.Resource.extend
  id                    : null
  formatted_card_number : null
  card_type             : null
  subscriptions         : null
  active                : null

  transactionProcessing : null

  activeSubscription: (->
    subscriptions = @get 'subscriptions'
    activeSubscription = _.find subscriptions, (subscription) ->
      subscription.state == 'active'
  ).property 'subscriptions'

  activePlan: (->
    if activeSubscription = @get 'activeSubscription'
      AIO.Plan.create activeSubscription.plan
  ).property 'activeSubscription'

  upgrade: (selectedPlanId, stripeToken, callback) ->
    # if plan or credit card details are not changed,
    # ignore the upgrade.
    unless stripeToken || this._isPlanChanged(selectedPlanId)
      return callback(null)

    $.ajax(
      url: '/subscription'
      type: this._upgradeType()
      data: { plan_id: selectedPlanId, stripe_token: stripeToken }
    ).done( =>
      # set this property,
      # so we can block user from
      # attempting to upgrade again.
      @set 'transactionProcessing', true
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
    activePlan = @get 'activePlan'
    return true unless activePlan
    return planId != activePlan.get('id')

  _upgradeType: ->
    # If the user has an exisiting active billing profile update it.
    if @get('id') && @get('active')
      'PUT'
    else
      'POST'
