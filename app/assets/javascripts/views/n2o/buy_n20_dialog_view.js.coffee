AIO.BuyN2oDialogView = AIO.IdeModalDialogView.extend
  templateName: 'templates/n2o/buy_n2o_dialog'
  elementId: 'buy_n2o_dialog_view'
  contentBinding: 'controller.buyN2oDialog' # N2oBonusController

  processing: false

  didInsertElement: ->
    $('#card_number').payment 'formatCardNumber'
    $('#card_expiration').payment 'formatCardExpiry'
    $('#card_cvc').payment 'formatCardCVC'
    $('#card_billing_zip').payment 'restrictNumeric'

  didClickBuy: ->
    @set 'processing', true
    card = @get 'content.card'
    if card.valid()
      card.createToken this._handleStripeResponse
    else
      @set 'processing', false

  _handleStripeResponse: (status, response) ->
    @set 'processing', false
    console.log response.error

