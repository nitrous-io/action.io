AIO.Addon = AIO.Model.extend
  uid: null
  description: null
  state: null
  addonPlans: null
  image: "https://partner-portal-8701.s3.amazonaws.com/assets/program/packages@2x-4bcca30e3d6726eea3b6f02b39462a3e.png"

  name: (->
    @get 'uid'
  ).property 'uid'

  firstPlan: (->
    @get 'addon_plans.0'
  ).property 'addon_plans'

  initializeAddonPlans: (->
    addonPlans = @get 'addonPlans'
    addonPlans = AIO.RecordArray.create(content: []) unless addonPlans
    addonPlans.deserialize AIO.AddonPlan, null, @get('addon_plans')
    @set 'addonPlans', addonPlans
  ).observes 'addon_plans.@each'

AIO.Addon.reopenClass
  resourceUrl: '/addons'
  resourceName: 'addon'
  jsonRoot: 'addons'
