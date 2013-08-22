AIO.Addon = AIO.Model.extend
  uid: null
  description: null
  state: null
  addonPlans: null
  image: null

  name: (->
    @get 'uid'
  ).property 'uid'

  deserialize: (json) ->
    @_super(json)
    addonPlans = @get 'addonPlans'
    addonPlans = AIO.RecordArray.create(content: []) unless addonPlans
    addonPlans.deserialize AIO.AddonPlan, null, json.addon_plans
    addonPlans.get('content').forEach (model) -> AIO.AddonPlan.addModel model
    @set 'addonPlans', addonPlans
    return this

AIO.Addon.reopenClass
  resourceUrl: '/addons'
  resourceName: 'addon'
  jsonRoot: 'addons'
