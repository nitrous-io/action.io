App.BoxesConfirmLeaveDialogView = App.IdeModalDialogView.extend
  templateName: 'templates/boxes/confirm-leave-dialog'
  elementId: 'boxes_confirm_leave_dialog_view'
  contentBinding: 'controller.confirmLeaveDialog' # BoxesIndexController

  didClickLeave: ->
    box = @get('content').get 'box'
    @get('controller').leave box
    this.hide()
