AIO.CreditCard = Em.Object.extend
  number: null
  cvc: null
  billingZip: null

  expirationMonth: null
  expirationYear: null

  errors: null

  expiration: ( (key, value) ->
    if arguments.length > 1
      {month, year} = $.payment.cardExpiryVal value
      @set 'expirationMonth', month
      @set 'expirationYear', year
    else
      expirationMonth = @get 'expirationMonth'
      expirationYear = @get 'expirationYear'

      if expirationMonth && expirationYear
        "#{expirationMonth}/#{expirationYear}"
  ).property 'expirationMonth', 'expirationYear'

  valid: ->
    errors = {}

    number = @get 'number'
    unless number && $.payment.validateCardNumber(number)
      errors.number = true

    expirationMonth = @get 'expirationMonth'
    expirationYear = @get 'expirationYear'
    unless expirationMonth && expirationYear && $.payment.validateCardExpiry(expirationMonth, expirationYear)
      errors.expiration = true

    cvc = @get 'cvc'
    cardType = $.payment.cardType(number)
    unless cvc && $.payment.validateCardCVC(cvc, cardType)
      errors.cvc = true

    unless @get('billingZip')
      errors.billingZip = true

    @set 'errors', errors

    return _.isEmpty(errors)

  createToken: (callback) ->
    Stripe.card.createToken this._stripeParams(), callback

  _stripeParams: ->
    {
      number: @get('number')
      cvc: @get('cvc')
      exp_month: @get('expirationMonth')
      exp_year: @get('expirationYear')
      address_zip: @get('billingZip')
    }
