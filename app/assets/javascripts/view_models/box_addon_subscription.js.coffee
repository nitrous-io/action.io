# this is a presenter of addon and addon_subscription model so we can display
# them both as one single object on the UI
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
  ).property 'subscription.state'

  isUnsubscribed: (->
    @get('subscription') == null || @get('subscription.state') == 'deprovisioned'
  ).property 'subscription.state'

  provisionState: (->
    @get 'subscription.state'
  ).property 'subscription.state'

  deprovision: ->
    @get('subscription').deprovision() if @get('isSubscribed')

  provision: ->
    if @get 'isUnsubscribed'
      model = AIO.AddonSubscription.provision @get('addon.id'), @get('box.id')
      @set 'subscription', model
