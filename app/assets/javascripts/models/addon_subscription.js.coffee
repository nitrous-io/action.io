AIO.AddonSubscription = AIO.Model.extend
  addon_plan_id: null
  box_id: null
  state: null
  env_vars: null

  # certain that addonPlan is preloaded so we dont need to query the server
  addonPlan: (->
    AIO.AddonPlan.findCache @get('addon_plan_id')
  ).property 'addon_plan_id'

  addonName: (->
    if addonPlan = @get('addonPlan')
      addonPlan.get 'addon.name'
  ).property 'addonPlan'

  planName: (->
    if addonPlan = @get('addonPlan')
      addonPlan.get 'name'
  ).property 'addonPlan'

  box: (->
    AIO.get('router.boxesController').findById @get('box_id')
  ).property 'box_id'

  stateTitle: (->
    if state = @get('state')
      "(" + state + ")"
  ).property 'state'

  isProvisioned: (->
    @get('state') == "provisioned"
  ).property 'state'

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

  provision: (addonPlanId, boxId) ->
    data =
      addon_subscription:
        addon_plan_id: addonPlanId
        box_id: boxId
    return Em.Deferred.promise (promise) =>
      model = AIO.AddonSubscription.create()
      model.set "isLoading", true
      success = (json) =>
        model.deserialize json.addon_subscription
        model.set "isLoading", false
        this.addModel model
        promise.resolve model
      failed = (json) =>
        promise.reject json
      this.ajax(this.buildURL(), data, "POST").then success, failed

  deprovision: (subscription) ->
    this.ajax(this.buildURL(subscription.get("id")), {}, "DELETE")
