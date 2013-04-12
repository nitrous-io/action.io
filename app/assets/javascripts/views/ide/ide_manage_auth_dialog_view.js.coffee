AIO.IdeManageAuthDialogView = AIO.IdeModalDialogView.extend
  templateName: 'templates/ide/manage_auth_dialog'
  elementId: 'ide_manage_auth_dialog_view'
  contentBinding: 'controller.manageAuthDialog.content' # controller = ideBasicAuthController
