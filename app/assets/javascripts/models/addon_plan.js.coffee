AIO.AddonPlan = AIO.Model.extend
  addon_id: null

  addon: (->
    AIO.Addon.findResource @get('addon_id')
  ).property 'addon_id'
