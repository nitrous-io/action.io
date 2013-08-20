AIO.CreditCard = Em.Object.extend
  number: null
  cvc: null
  billing_zip: null

  expirationMonth: null
  expirationYear: null

  expirationString: ( (key, value) ->
    if arguments.length > 1
      { @expirationMonth, @expirationYear } = $.payment.cardExpiryVal value
    else
      if @expirationMonth && @expirationYear
        "#{@expirationMonth}/#{@expirationYear}"
  ).property 'expirationMonth', 'expirationYear'
