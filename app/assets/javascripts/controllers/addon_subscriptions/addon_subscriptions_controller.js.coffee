AIO.AddonSubscriptionsController = AIO.ResourceController.extend
  resourceType: AIO.AddonSubscription
  jsonRoot: 'addon_subscriptions'

  # current box that contains the subscriptions
  box: null

  findAll: ->
    AIO.AddonSubscription.fetch @get('box.id'), (err, models) =>
      @set 'content', models unless err
