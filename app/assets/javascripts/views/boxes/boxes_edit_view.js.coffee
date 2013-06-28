AIO.BoxesEditView = AIO.BoxesControlView.extend
  templateName: 'templates/boxes/edit'
  classNames: ['app_page', 'edit']
  elementId: 'boxes_edit_view'

  startingMemoryCost: null
  startingStorageCost: null

  memoryBinding: 'controller.content.memory'
  storageBinding: 'controller.content.storage'

  didInsertElement: ->
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

  didClickChangeBox: (event) ->
    @get('controller').save()

  didClickCancel: (event) ->
    @get('controller').cancel()
