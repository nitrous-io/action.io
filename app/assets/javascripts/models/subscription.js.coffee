AIO.Subscription = AIO.Resource.extend
  state     : null
  plan_id   : null

  active: (->
    @get('state') == 'active'
  ).property 'state'

  plan: (->
    AIO.get('router.plansController').findById @get('plan_id')
  ).property 'plan_id'

  #TODO: Needs a test
  changePlan: (planId, callback) ->
    $.ajax(
      url: '/subscription'
      type: 'PUT'
      data: { plan_id: planId }
    ).done( =>
      # Set flag to prevent user to access upgrade/change plan pages until the
      # current one is processed.
      @set 'processing', true
      callback(null)
    ).fail (e) =>
      response = $.parseJSON e.responseText
      errorMessage = response.errors?.base?[0]
      callback errorMessage

  #TODO: Needs a test
  cancel: (callback) ->
    $.ajax(
      url: '/subscription'
      type: 'DELETE'
    ).done( =>
      callback(null)
    ).fail (e) =>
      response = $.parseJSON e.responseText
      errorMessage = response.errors?.base?[0]
      callback errorMessage

AIO.Subscription.reopenClass
  #TODO: Needs a test
  subscribe: (planId, stripeToken, callback) ->
    unless stripeToken
      return callback(null)

    $.ajax(
      url: '/subscription'
      type: 'POST'
      data: { plan_id: planId, stripe_token: stripeToken }
    ).done( =>
      callback(null)
    ).fail (e) =>
      response = $.parseJSON e.responseText
      errorMessage = response.errors?.base?[0]
      callback errorMessage
