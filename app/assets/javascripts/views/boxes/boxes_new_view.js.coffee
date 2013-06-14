AIO.BoxesNewView = Em.View.extend
  regionsBinding: 'AIO.router.regionsController'
  boxTemplatesBinding: 'AIO.router.boxTemplatesController'

  templateName: 'templates/boxes/new'
  classNames: ['app_page', 'new']
  elementId: 'boxes_new_view'

  memoryBinding: 'controller.content.memory'
  storageBinding: 'controller.content.storage'

  memoryCost: (->
    unitPrice = AIO.get 'n2o128mbMemory'
    @get('memory') / 128 * unitPrice
  ).property 'memory'

  storageCost: (->
    unitPrice = AIO.get 'n2o250mbStorage'
    @get('storage') / 250 * unitPrice
  ).property 'storage'

  totalCost: (->
    @get('memoryCost') + @get('storageCost')
  ).property 'memoryCost', 'storageCost'

  didClickCreateBox: (event) ->
    @get('controller').save()

  didClickCancel: (event) ->
    @get('controller').cancel()
