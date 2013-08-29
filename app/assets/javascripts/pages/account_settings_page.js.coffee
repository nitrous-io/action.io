#= require jquery
#= require jquery_ujs
#= require jquery.payment
window.AIO ||= {}

AIO.AccountSettingsPage =
  initialize: (stripe_key) ->
    Stripe.setPublishableKey stripe_key

    $('#updateCardBtn').on 'click', =>
      this.didClickUpdateCard()
    $('#changePlanBtn').on 'click', =>
      this.didClickChangePlan()

    $('#card_number').payment 'formatCardNumber'
    $('#card_expiration').payment 'formatCardExpiry'
    $('#card_cvc').payment 'formatCardCVC'
    $('#card_billing_zip').payment 'restrictNumeric'

  didClickUpdateCard: ->
    Stripe.card.createToken this._stripeParams(), (status, response) =>
      this._handleStripeResponse response

  didClickChangePlan: ->
    this._updateSubsription { plan_id: $("#subscription_plan").val() }

  _handleStripeResponse: (response) ->
    if response.error
      this._setFormError response.error.message
    else
      this._updateSubsription { stripe_token: response.id }

  _updateSubsription: (data) ->
    $.ajax(
      url: '/subscription'
      type: 'put'
      data: data
    ).done((json) =>
      $(this).hide()
    ).fail (xhr, textStatus, error) =>
      errors = JSON.parse xhr.responseText
      errorMessage = errors.base
      this._setFormError errorMessage

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
