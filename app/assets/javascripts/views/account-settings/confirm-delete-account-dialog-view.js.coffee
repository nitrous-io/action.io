App.ConfirmDeleteAccountDialogView = App.IdeModalDialogView.extend
  templateName: 'templates/account-settings/confirm-delete-account-dialog'
  elementId: 'confirm_delete_account_dialog_view'
  contentBinding: 'controller.confirmDeleteAccountDialog' # AccountSettingsIndexController

  didClickProceed: ->
    @get('controller').deleteAccount()
    this.hide()
