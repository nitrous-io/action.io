AIO.ConfirmBoxTerminateView = AIO.IdeModalDialogView.extend
  templateName: 'templates/boxes/confirm_terminate'
  elementId: 'box_confirm_terminate_view'
  contentBinding: 'controller.confirmBoxTerminate' # BoxesIndexController

  dontAllowTerminate: true

  viewDidAppear: ->
    @$('#box_name').focus()

  didClickTerminate: ->
    box = @get('content').get 'box'
    @get('controller').terminate box
    this.hide()

AIO.ConfirmBoxTerminateTextField = Em.TextField.extend
  insertNewline: ->
    @get('parentView').didClickTerminate()

  keyUp: (event, view) ->
    parentView = @get('parentView')
    box = parentView.content?.get 'box'
    boxName = box.get 'name'
    enteredName = @get 'value'

    parentView.set 'dontAllowTerminate', (enteredName != boxName)

