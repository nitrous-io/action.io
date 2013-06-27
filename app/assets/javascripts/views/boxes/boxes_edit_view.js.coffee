AIO.BoxesEditView = AIO.BoxesControlView.extend
  templateName: 'templates/boxes/edit'
  classNames: ['app_page', 'edit']
  elementId: 'boxes_edit_view'

  memoryBinding: 'controller.content.memory'
  storageBinding: 'controller.content.storage'

  changeButtonDisabled: (->
    @get('insufficientN2O') || @get('controller.content.saving')
  ).property 'controller.content.saving', 'insufficientN2O'

  didClickChangeBox: (event) ->
    @get('controller').save()

  didClickCancel: (event) ->
    @get('controller').cancel()
