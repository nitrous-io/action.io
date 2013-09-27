AIO.SubscriptionPlansCollection = Em.ArrayProxy.extend
  content: null

AIO.SubscriptionPlan = AIO.Resource.extend
  name              : null
  price             : null
  interval          : null
  highlight         : null
  display_order     : null
  n2o_amount        : null

  priceFormatted: (->
    price = @get 'price'
    "$#{price.toFixed(2)}"
  ).property 'price'

  featuresArray: (->
    if features = @get 'features'
      $.trim(features).split '|'
  ).property 'features'

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

