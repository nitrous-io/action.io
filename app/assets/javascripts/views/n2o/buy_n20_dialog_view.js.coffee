AIO.BuyN2oDialogView = AIO.IdeModalDialogView.extend
  templateName: 'templates/n2o/buy_n2o_dialog'
  elementId: 'buy_n2o_dialog_view'
  contentBinding: 'controller.buyN2oDialog' # N2oBonusController

  processing: false
  processingErrorMessage: null

  didInsertElement: ->
    $('#card_number').payment 'formatCardNumber'
    $('#card_expiration').payment 'formatCardExpiry'
    $('#card_cvc').payment 'formatCardCVC'
    $('#card_billing_zip').payment 'restrictNumeric'

  didClickBuy: ->
    @set 'processing', true
    card = @get 'content.card'
    if card.valid()
      card.createToken (status, response) =>
        this._handleStripeResponse response
    else
      @set 'processing', false

  _handleStripeResponse: (response) ->
    if response.error
      this._resetFormOnError response.error.message
    else
      this._createSubsription response.id

  _createSubsription: (token) ->
    @get('content').createSubscription token, (err) =>
      if err
        this._resetFormOnError err
      else
        this.hide()

  _resetFormOnError: (error) ->
    @set 'processing', false
    @set 'processingErrorMessage', error

