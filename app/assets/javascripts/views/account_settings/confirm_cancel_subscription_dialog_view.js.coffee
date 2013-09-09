AIO.ConfirmCancelSubscriptionDialogView = AIO.IdeModalDialogView.extend
  templateName: 'templates/account_settings/confirm_cancel_subscription_dialog'
  elementId: 'confirm_cancel_subscription_dialog_view'
  contentBinding: 'controller.confirmCancelSubscriptionDialog' # AccountSettingsIndexController

  didClickProceed: ->
    @get('controller').cancelSubscription()
    this.hide()

AIO.ConfirmTerminateDialogTextField = Em.TextField.extend
  insertNewline: (event) ->
    @get('parentView').didClickTerminate()
