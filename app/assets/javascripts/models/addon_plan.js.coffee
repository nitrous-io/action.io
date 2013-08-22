AIO.AddonPlan = AIO.Model.extend
  addon_id: null

  addon: (->
    AIO.Addon.findCache @get('addon_id')
  ).property 'addon_id'
