AIO.BoxesConfirmLeaveDialogView = AIO.IdeModalDialogView.extend
  templateName: 'templates/boxes/confirm_leave_dialog'
  elementId: 'boxes_confirm_leave_dialog_view'
  contentBinding: 'controller.confirmLeaveDialog' # BoxesIndexController

  didClickLeave: ->
    box = @get('content').get 'box'
    @get('controller').leave box
    this.hide()
