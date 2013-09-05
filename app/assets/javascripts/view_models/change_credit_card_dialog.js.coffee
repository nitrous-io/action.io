AIO.ChangeCreditCardDialog = Em.Object.extend
  card: null
  errorMessage: null

  updateCard: (callback) ->
    billingProfile = AIO.get 'billingProfile'
    card = @get 'card'

    @set 'errorMessage', null

    card.createToken (error, stripeToken) =>
      if error
        @set 'errorMessage', error
        callback(error)
      else
        billingProfile.upgrade null, stripeToken, (error) =>
          if error
            @set 'errorMessage', error
          callback(error)
