AIO.BoxFormView = AIO.BoxesControlView.extend
  templateName: 'templates/boxes/form'
  elementId: 'boxes_form_view'
  content: null

  regions: (->
    AIO.Region.all()
  ).property()

  boxTemplates: (->
    AIO.BoxTemplate.all()
  ).property()

  snapshotsBinding: 'AIO.currentUser.completedSnapshots'

  memoryBinding: 'controller.content.memory'
  storageBinding: 'controller.content.storage'

  createBoxButtonDisabled: (->
    @get('insufficientN2O') || @get('controller.content.saving')
  ).property 'controller.content.saving', 'insufficientN2O'

  didClickCreateBox: (event) ->
    @get('controller').save()

  didClickCancel: (event) ->
    @get('controller').cancel()

  keyPress: (event) ->
    if event.target.id == 'box_name'
      @set 'controller.boxNameIsDirty', true

AIO.BoxNameTextField = Em.TextField.extend
  click: ->
    unless @get 'controller.boxNameIsDirty'
      @$().select()
