AIO.BoxesEditController = Em.ObjectController.extend
  addons: null
  subscriptions: null

  # merge of addon and subscriptions
  # this always contain the list of all addons, and the box subscription for
  # that addon if it exist
  #
  # list of `AIO.BoxAddonSubscription`
  addonSubscriptionsChanged: (->
    return unless @get('addons')
    addonSubscriptions = []
    @get('addons').forEach (addon) =>
      model = AIO.BoxAddonSubscription.create addon: addon, box: @get('content')
      subscription = @get('subscriptions').findProperty 'addon_plan_id', addon.get('firstPlan.id')
      model.set 'subscription', subscription if subscription
      addonSubscriptions.push model
    @set 'addonSubscriptions', addonSubscriptions
  ).observes 'addons.@each', 'subscriptions.@each'

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
