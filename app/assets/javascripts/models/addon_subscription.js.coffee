AIO.AddonSubscription = AIO.Resource.extend
  addon_id: null
  box_id: null
  state: null

  resourceUrl: "/addon_subscriptions"
  resourceName: "addon_subscription"

  addon: (->
    AIO.get('router.addonsController').findById 'addon'
  ).property 'addon_id'

  box: (->
    AIO.get('router.boxesController').findById 'box_id'
  ).property 'box_id'

  deprovision: ->
    $.ajax(
      type: 'DELETE'
      dataType: 'json'
      url: "/addon_subscriptions/#{@get('id')}"
    ).done((json) ->
    ).fail (json) ->

AIO.AddonSubscription.reopenClass
  fetch: (boxId, callback) ->
    klass = this
    $.ajax(
      type: 'GET'
      dataType: 'json'
      url: "/boxes/#{boxId}/addon_subscriptions"
    ).done((json) ->
      models = _.map json.addon_subscriptions, (attrs) ->
        klass.create attrs
      callback null, models
    ).fail (json) ->
      callback json

  provision: (addonId, boxId, callback) ->
    klass = this
    $.ajax(
      type: 'POST'
      dataType: 'json'
      url: "/addon_subscriptions"
      data: {
        addon_subscription: {
          addon_id: addonId
          box_id: boxId
        }
      }
    ).done((json) ->
      model = klass.create json.addon_subscription
      callback null, model
    ).fail (json) ->
      callback json
