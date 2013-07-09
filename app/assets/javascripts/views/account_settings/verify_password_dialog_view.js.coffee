AIO.VerifyPasswordDialogView = AIO.IdeModalDialogView.extend
  templateName: 'templates/account_settings/verify_password_dialog'
  elementId: 'verify_password_dialog_view'
  contentBinding: 'controller.verifyPasswordDialog' # AccountSettingsIndexController

  didInsertElement: ->

  didClickOk: ->
