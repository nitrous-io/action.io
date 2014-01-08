AIO.ConfirmDeleteAccountDialogView = AIO.IdeModalDialogView.extend
  templateName: 'templates/account_settings/confirm_delete_account_dialog'
  elementId: 'confirm_delete_account_dialog_view'
  contentBinding: 'controller.confirmDeleteAccountDialog' # AccountSettingsIndexController

  didClickProceed: ->
    @get('controller').deleteAccount()
    this.hide()
