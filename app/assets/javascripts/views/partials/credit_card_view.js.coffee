AIO.CreditCardView = Em.View.extend
  templateName: 'templates/partials/credit_card'
  elementId: 'credit_card_view'

  card: null

  didInsertElement: ->
    # make form fields behave as payment fields
    $('#card_number').payment 'formatCardNumber'
    $('#card_expiration').payment 'formatCardExpiry'
    $('#card_cvc').payment 'formatCardCVC'
    $('#card_billing_zip').payment 'restrictNumeric'
