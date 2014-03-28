AIO.ChangeCreditCardDialogView = AIO.IdeModalDialogView.extend
  templateName: 'templates/credit_cards/change_credit_card_dialog'
  elementId: 'change_credit_card_dialog_view'
  contentBinding: 'controller.changeCreditCardDialog' # AccountSettingsIndexController

  changing: false

  didClickChange: ->
    content = @get 'content'
    @set 'changing', true
    content.updateCard (error) =>
      @set 'changing', false
      unless error
        this.hide()
