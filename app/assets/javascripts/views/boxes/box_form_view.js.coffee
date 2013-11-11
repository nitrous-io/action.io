AIO.BoxFormView = AIO.BoxesControlView.extend
  templateName: 'templates/boxes/form'
  classNames: ['app_page', 'new']
  classNameBindings: ['controller.isLightningMode:lightning-mode']
  content: null

  regionsBinding: 'AIO.router.regionsController'
  boxTemplatesBinding: 'AIO.router.boxTemplatesController'

  memoryBinding: 'controller.content.memory'
  storageBinding: 'controller.content.storage'

  createBoxButtonDisabled: (->
    @get('insufficientN2O') || @get('controller.content.saving')
  ).property 'controller.content.saving', 'insufficientN2O'

  didClickCreateBox: (event) ->
    @get('controller').save()

  didClickCancel: (event) ->
    @get('controller').cancel()
