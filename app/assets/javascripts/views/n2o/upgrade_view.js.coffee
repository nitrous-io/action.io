AIO.N2oUpgradeView = Em.View.extend
  templateName: 'templates/n2o/upgrade'
  classNames: ['app_page']
  elementId: 'n2o_upgrade_view'

  processing: false
  processingErrorMessage: null

  didInsertElement: ->
    $('#card_number').payment 'formatCardNumber'
    $('#card_expiration').payment 'formatCardExpiry'
    $('#card_cvc').payment 'formatCardCVC'
    $('#card_billing_zip').payment 'restrictNumeric'

  didClickBuy: ->
    @set 'processing', true
    @set 'processingErrorMessage', null
    controller = @get 'controller'
    card = controller.get 'card'
    if card.valid()
      card.createToken (status, response) =>
        this._handleStripeResponse response
    else
      @set 'processing', false

  _handleStripeResponse: (response) ->
    if response.error
      this._setFormError response.error.message
    else
      this._createSubsription response.id

  _createSubsription: (token) ->
    controller = @get 'controller'
    controller.createSubscription token, (err) =>
      if err
        this._setFormError err
      else
        @set 'processing', false
        #TODO: Set flash message
        AIO.get('router').transitionTo 'n2o.bonus'

  _setFormError: (error) ->
    @set 'processing', false
    @set 'processingErrorMessage', error
