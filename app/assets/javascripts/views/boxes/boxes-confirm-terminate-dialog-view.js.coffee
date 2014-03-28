AIO.BoxesConfirmTerminateDialogView = AIO.IdeModalDialogView.extend
  templateName: 'templates/boxes/confirm_terminate_dialog'
  elementId: 'boxes_confirm_terminate_dialog_view'
  contentBinding: 'controller.confirmTerminateDialog' # BoxesIndexController

  enteredName: null

  nameMismatch: (->
    @get('enteredName') != @get('content.box.name')
  ).property 'enteredName', 'content.box.name'

  viewDidAppear: ->
    @set 'enteredName', null
    @$('#box_name').focus()

  didClickTerminate: ->
    box = @get('content').get 'box'
    unless @get 'nameMismatch'
      @get('controller').terminate box
      this.hide()

AIO.BoxesConfirmTerminateDialogTextField = Em.TextField.extend
  insertNewline: (event) ->
    @get('parentView').didClickTerminate()
