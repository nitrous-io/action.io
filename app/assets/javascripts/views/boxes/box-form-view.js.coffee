#= require ./boxes-control-view

App.BoxFormView = App.BoxesControlView.extend
  templateName: 'templates/boxes/form'
  elementId: 'boxes_form_view'
  content: null

  snapshotsBinding: 'App.currentUser.completedSnapshots'

  memoryBinding: 'controller.content.memory'
  storageBinding: 'controller.content.storage'

  createBoxButtonDisabled: (->
    @get('insufficientN2O') || @get('controller.content.saving')
  ).property 'controller.content.saving', 'insufficientN2O'

  didClickCreateBox: (event) ->
    @get('controller').save()

  didClickCancel: (event) ->
    @get('controller').cancel()

App.BoxNameTextField = Em.TextField.extend
  click: ->
    unless @get 'controller.boxNameIsDirty'
      @$().select()

  keyPress: (event) ->
    @set 'controller.boxNameIsDirty', true
