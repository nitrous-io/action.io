AIO.BoxAddonSubscription = Em.Object.extend
  addon: null
  subscription: null
  box: null
  isLoading: false

  name: (->
    @get 'addon.name'
  ).property 'addon'

  isSubscribed: (->
    @get('subscription.state') == 'provisioned'
  ).property 'subscription'

  isUnsubscribed: (->
    @get('subscription') == null || @get('subscription.state') == 'deprovisioned'
  ).property 'subscription'

  provisionState: (->
    @get 'subscription.state'
  ).property 'subscription.state'

  toggleProvision: ->
    if @get('isSubscribed')
      @get('subscription').deprovision()
    else if @get 'isUnsubscribed'
      @set 'isLoading', true
      AIO.AddonSubscription.provision @get('addon.id'), @get('box.id'), (err, model) =>
        @set 'subscription', model
        @set 'isLoading', false

