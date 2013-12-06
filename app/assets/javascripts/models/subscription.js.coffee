AIO.Subscription = AIO.Resource.extend
  state                 : null
  plan                  : null

  active: (->
    _.contains ['active', 'past_due'], @get('state')
  ).property 'state'

  activePlan: (->
    if @get('state') == 'active'
      AIO.Plan.create @get('plan')
  ).property 'state', 'plan'
