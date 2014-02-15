AIO.BoxesEditResourcesView = AIO.BoxesControlView.extend
  templateName: 'templates/boxes/edit_resources'
  classNames: ['app_page', 'edit']
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

  didClickCancel: (event) ->
    @get('controller').cancel()
