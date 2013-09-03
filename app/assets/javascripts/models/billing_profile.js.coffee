AIO.BillingProfile = AIO.Resource.extend
  formatted_card_number : null
  card_type             : null
  subscriptions         : null

  activeSubscription: (->
    subscriptions = @get 'subscriptions'
    activeSubscription = _.find subscriptions, (subscription) ->
      subscription.state == 'active'
  ).property 'subscriptions'
