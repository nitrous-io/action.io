AIO.Subscription = AIO.Resource.extend
  state     : null
  plan_id   : null

  active: (->
    @get('state') == 'active'
  ).property 'state'

  plan: (->
    AIO.get('router.allPlansController').findById @get('plan_id')
  ).property 'plan_id'

  changePlan: (planId, callback) ->
    $.ajax(
      url: '/subscription'
      type: 'PUT'
      data: { plan_id: planId }
    ).done( =>
      callback(null)
    ).fail (e) =>
      response = $.parseJSON e.responseText
      errorMessage = response.errors?.base?[0]
      callback errorMessage

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
