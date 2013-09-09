AIO.SubscriptionPlansCollection = Em.ArrayProxy.extend
  content: null

AIO.SubscriptionPlan = AIO.Resource.extend
  name              : null
  price             : null
  interval          : null
  highlight         : null
  display_order     : null

  pricePerInterval: (->
    price = @get 'price'
    interval = @get 'interval'

    "$#{price} / #{interval}"
  ).property 'price', 'interval'

  priceFormatted: (->
    price = @get 'price'
    "$#{price.toFixed(2)}"
  ).property 'price'

AIO.SubscriptionPlan.reopenClass
  fetchAll: (callback) ->
    klass = this
    $.ajax(
      type: 'GET'
      dataType: 'json'
      url: "/subscription/plans"
    ).done((json) ->
      models = _.map json.plans, (attrs) ->
        klass.create attrs
      callback null, models
    ).fail (json) ->
      callback json

