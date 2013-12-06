AIO.Subscription = AIO.Resource.extend
  state                 : null
  plan_id               : null

  active: (->
    _.contains ['active', 'past_due'], @get('state')
  ).property 'state'

  plan: (->
    AIO.get('router.plansController').findById @get('plan_id')
  ).property 'plan_id'

