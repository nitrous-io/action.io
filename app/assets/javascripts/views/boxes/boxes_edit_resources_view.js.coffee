AIO.BoxesEditResourcesView = AIO.BoxesControlView.extend AIO.SettingsViewMixin,
  templateName: 'templates/boxes/edit_resources'
  classNames: ['app_page', 'edit', 'settings']
  elementId: 'boxes_edit_resources_view'

  startingMemoryCost: null
  startingStorageCost: null

  memoryBinding: 'controller.content.memory'
  storageBinding: 'controller.content.storage'
  memoryUsageBinding: 'controller.content.memory_usage'
  storageUsageBinding: 'controller.content.storage_usage'
  nameBinding: 'controller.content.name'

  didInsertElement: ->
    box = @get 'controller.content'
    box.fetchBoxInfo()
    @set 'startingMemoryCost', @get('memoryCost')
    @set 'startingStorageCost', @get('storageCost')

  memoryCostChange: (->
    0 - (@get('memoryCost') - @get('startingMemoryCost'))
  ).property 'memoryCost', 'startingMemoryCost'

  storageCostChange: (->
    0 - (@get('storageCost') - @get('startingStorageCost'))
  ).property 'storageCost', 'startingStorageCost'

  totalCostChange: (->
    @get('memoryCostChange') + @get('storageCostChange')
  ).property 'memoryCostChange', 'storageCostChange'

  remainingN2O: (->
    @get('freeN2O') + @get('totalCostChange')
  ).property 'freeN2O', 'totalCostChange'

  insufficientStorage: (->
    @get('storage') <= @get('storageUsage')
  ).property 'storage', 'storageUsage'

  saveChangesButtonDisabled: (->
    @get('insufficientN2O') || @get('controller.content.saving') || @get('insufficientStorage')
  ).property 'controller.content.saving', 'insufficientN2O'

  memoryUsageDetails: (->
    memoryUsage = @get 'memoryUsage'
    memoryAllocated = @get 'memory'

    if memoryUsage && memoryAllocated
      if memoryUsage == -1
        "N/A (not running)"
      else
        "#{memoryUsage.toFixed(1)}MB of #{memoryAllocated}MB used"
  ).property 'memoryUsage', 'memory'

  storageUsageDetails: (->
    storageUsage = @get 'storageUsage'
    storageAllocated = @get 'storage'

    if storageUsage && storageAllocated
      "#{storageUsage.toFixed(1)}MB of #{storageAllocated}MB used"
  ).property 'storageUsage', 'storage'

  didClickChangeBox: (event) ->
    @get('controller').save()
    boxState = @get('controller.content.state')
    if boxState == 'stopped'
      AIO.set 'flashMessage', { type: 'alert-info', text: 'Changes will take place the next time your box is started' }
    else if boxState == 'running'
      AIO.set 'flashMessage', { type: 'alert-info', text: 'Your changes have been saved.  Your box should be updated in the next five minutes.' }

  didClickCancel: (event) ->
    @get('controller').cancel()
