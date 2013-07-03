AIO.BoxesEditView = AIO.BoxesControlView.extend
  templateName: 'templates/boxes/edit'
  classNames: ['app_page', 'edit']
  elementId: 'boxes_edit_view'

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
    @get('memoryCost') - @get('startingMemoryCost')
  ).property 'memoryCost', 'startingMemoryCost'

  storageCostChange: (->
    @get('storageCost') - @get('startingStorageCost')
  ).property 'storageCost', 'startingStorageCost'

  totalCostChange: (->
    @get('memoryCostChange') + @get('storageCostChange')
  ).property 'memoryCostChange', 'storageCostChange'

  remainingN2O: (->
    @get('freeN2O') - @get('totalCostChange')
  ).property 'freeN2O', 'totalCostChange'

  changeButtonDisabled: (->
    @get('insufficientN2O') || @get('controller.content.saving')
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
