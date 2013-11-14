AIO.IdeManageAutopartsDialogView = AIO.IdeModalDialogView.extend
  templateName: 'templates/ide/manage_autoparts_dialog'
  elementId: 'ide_manage_autoparts_dialog_view'
  contentBinding: 'controller.manageAutopartsDialog' # controller = ideAutopartsController

  didClickRefresh: ->
