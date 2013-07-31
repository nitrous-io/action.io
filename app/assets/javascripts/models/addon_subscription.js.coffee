AIO.AddonSubscription = AIO.Model.extend
  addon_id: null
  box_id: null
  state: null

  addon: (->
    AIO.Addon.findResource @get('addon_id')
  ).property 'addon_id'

  box: (->
    AIO.get('router.boxesController').findById @get('box_id')
  ).property 'box_id'
  
  deprovision: ->
    @set 'isLoading', true
    AIO.AddonSubscription.deprovision(this).then (json) =>
      this.deserialize json.addon_subscription
      @set "isLoading", false
    this

AIO.AddonSubscription.reopenClass
  resourceUrl: "/addon_subscriptions"
  resourceName: "addon_subscription"
  jsonRoot: "addon_subscriptions"

  # TODO: handle customizable resourceUrl for an instance
  # For now this is copy-pasted from AIO.Model
  fetch: (boxId) ->
    this._data = AIO.RecordArray.create(content: []) unless this._data
    this._data.set 'isLoading', true
    url = "/boxes/#{boxId}/addon_subscriptions.json"
    this.ajax(url).then (json) =>
      this._data.deserialize this, this.jsonRoot, json
      this._data.set 'isLoading', false
    return this._data

  provision: (addonId, boxId) ->
    data =
      addon_subscription:
        addon_id: addonId
        box_id: boxId
    model = AIO.AddonSubscription.create()
    model.set "isLoading", true
    this.ajax(this.buildURL(), data, "POST").then (json) =>
      model.deserialize json.addon_subscription
      model.set "isLoading", false
      this.addModel model
    model

  deprovision: (addon) ->
    this.ajax(this.buildURL(addon.get("id")), {}, "DELETE")
