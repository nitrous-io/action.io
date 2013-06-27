AIO.BoxesNewView = AIO.BoxesControlView.extend
  regionsBinding: 'AIO.router.regionsController'
  boxTemplatesBinding: 'AIO.router.boxTemplatesController'

  templateName: 'templates/boxes/new'
  classNames: ['app_page', 'new']
  elementId: 'boxes_new_view'

  memoryBinding: 'controller.content.memory'
  storageBinding: 'controller.content.storage'

  createBoxButtonDisabled: (->
    @get('insufficientN2O') || @get('controller.content.saving')
  ).property 'controller.content.saving', 'insufficientN2O'

  didClickCreateBox: (event) ->
    @get('controller').save()

  didClickCancel: (event) ->
    @get('controller').cancel()
