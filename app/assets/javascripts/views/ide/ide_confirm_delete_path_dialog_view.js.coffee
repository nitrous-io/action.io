AIO.IdeConfirmDeletePathDialogView = AIO.IdeModalDialogView.extend
  templateName: 'templates/ide/confirm_delete_path_dialog'
  elementId: 'confirm_delete_path_dialog_view'
  contentBinding: 'controller.confirmDeletePathDialog' # IdeSidebarController

  didClickDelete: ->
    if path = @get('content.path')
      controller = @get('controller')
      @set 'content', null
      controller.delete path

