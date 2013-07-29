AIO.BoxesEditController = Em.ObjectController.extend
  addonSubscriptions: null

  addons: (->
    AIO.get 'router.addonsController.content'
  ).property 'AIO.router.addonsController.content'

  subscriptions: (->
    AIO.get 'router.addonSubscriptionsController.content'
  ).property 'AIO.router.addonSubscriptionsController.content'
  
  # merge of addon and subscriptions
  # this always contain the list of all addons, and the box subscription for
  # that addon if it exist
  #
  # list of `AIO.BoxAddonSubscription`
  addonSubscriptionsChanged: (->
    addonSubscriptions = []
    for addon in @get('addons')
      model = AIO.BoxAddonSubscription.create addon: addon, box: @get('content')
      for subscription in @get('subscriptions')
        if subscription.get('addon_id') == addon.get('id')
          model.set 'subscription', subscription
      addonSubscriptions.push model
    @set 'addonSubscriptions', addonSubscriptions
  ).observes 'addons', 'subscriptions'

  save: ->
    record = @get 'content'
    record.set 'saving', true
    record.saveResource()
      .fail (e) ->
        if e.status == 422
          record.set 'errors', $.parseJSON(e.responseText).errors
      .done ->
        AIO.get('router').transitionTo 'boxes.index'
      .always ->
        record.set 'saving', false

  cancel: ->
    AIO.get('router').transitionTo 'boxes.index'
