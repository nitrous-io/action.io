App.BoxesIndexConfirmTerminateDialogView = App.IdeModalDialogView.extend
  templateName: 'templates/boxes/index-confirm-terminate-dialog'
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
      box.terminate()
      this.hide()

App.BoxesConfirmTerminateDialogTextField = Em.TextField.extend
  insertNewline: (event) ->
    @get('parentView').didClickTerminate()
