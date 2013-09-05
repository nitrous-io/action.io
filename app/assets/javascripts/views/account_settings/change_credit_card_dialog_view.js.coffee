AIO.ChangeCreditCardDialogView = AIO.IdeModalDialogView.extend
  templateName: 'templates/account_settings/change_credit_card_dialog'
  elementId: 'change_credit_card_dialog_view'
  contentBinding: 'controller.changeCreditCardDialog' # AccountSettingsIndexController
  cardBinding: 'controller.card' # AccountSettingsIndexController

  changing: false

  didClickChange: ->
    content = @get 'content'
    @set 'changing', true
    content.updateCard (error) =>
      @set 'changing', false
      unless error
        this.hide()
