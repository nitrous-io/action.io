AIO.BillingProfile = AIO.Resource.extend
  id                    : null
  formatted_card_number : null
  card_type             : null

  #TODO: Needs a test
  changeCard: (stripeToken, callback) ->
    unless stripeToken
      return callback(null)

    $.ajax(
      url: '/subscription/change_card'
      type: 'PUT'
      data: { stripe_token: stripeToken }
    ).done( =>
      callback(null)
    ).fail (e) =>
      response = $.parseJSON e.responseText
      errorMessage = response.errors?.base?[0]
      callback errorMessage
