#= require jquery
#= require jquery_ujs
#= require jquery.payment
window.AIO ||= {}

AIO.AccountSettingsPage =
  initialize: (stripe_key) ->
    Stripe.setPublishableKey stripe_key

    $('#updateCardBtn').on 'click', =>
      this.didClickUpdate()
    $('#card_number').payment 'formatCardNumber'
    $('#card_expiration').payment 'formatCardExpiry'
    $('#card_cvc').payment 'formatCardCVC'
    $('#card_billing_zip').payment 'restrictNumeric'

  didClickUpdate: ->
    Stripe.card.createToken this._stripeParams(), (status, response) =>
      this._handleStripeResponse response

  _handleStripeResponse: (response) ->
    if response.error
      this._setFormError response.error.message
    else
      this._createSubsription response.id

  _createSubsription: (token) ->
    $.ajax(
      url: '/subscription'
      type: 'put'
      data: { stripe_token: token }
    ).done((json) =>
      $(this).hide()
    ).fail (xhr, textStatus, error) =>
      this._setFormError error

  _stripeParams: ->
    cardExpiryVal = $.payment.cardExpiryVal $('#card_expiration').val()
    {
      number: $('#card_number').val()
      cvc: $('#card_cvc').val()
      exp_month: cardExpiryVal.month
      exp_year: cardExpiryVal.year
      address_zip: $('#card_billing_zip').val()
    }

  _setFormError: (error) ->
    $('#errors').text(error)
    $('#errors').toggleClass 'hide show'
