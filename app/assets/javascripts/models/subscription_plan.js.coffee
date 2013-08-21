AIO.SubscriptionPlan = AIO.Resource.extend
  name              : null
  price             : null
  interval          : null
  highlight         : null
  display_order     : null

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

