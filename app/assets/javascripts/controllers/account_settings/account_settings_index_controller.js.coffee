AIO.AccountSettingsIndexController = Em.ObjectController.extend
  content: null
  resettingPassword: false
  cancelingSubscription: false

  changeCreditCardDialog: null
  card: null

  init: ->
    @_super()
    @set 'content', AIO.get('currentUser')
    @set 'card', AIO.CreditCard.create()

  hasActiveBillingProfile: (->
    if billingProfile = AIO.get 'billingProfile'
      billingProfile.get 'active'
  ).property 'AIO.billingProfile'

  currentPlanName: (->
    if billingProfile = AIO.get 'billingProfile'
      activeSubscriptionPlan = billingProfile.get 'activeSubscriptionPlan'
      activeSubscriptionPlan.name
  ).property 'AIO.billingProfile'

  currentCardDetails: (->
    if billingProfile = AIO.get 'billingProfile'
      formattedCardNumber = billingProfile.get('formatted_card_number')
      cardType = billingProfile.get('card_type')
      "#{formattedCardNumber} (#{cardType})"
  ).property 'AIO.billingProfile'

  resetPassword: ->
    @set 'resettingPassword', true
    record = @get 'content'
    record.resetPassword()
          .done =>
            AIO.set 'flashMessage', { type: 'alert-info', text: 'Check your email for instructions on resetting your password.' }
          .always =>
            @set 'resettingPassword', false

  updateProfile: ->
    record = @get 'content'
    record.set 'errors', null
    record.updateInfo()
          .done ->
            AIO.set 'flashMessage', { type: 'alert-success', text: 'Your account details were updated successfully.' }

  changeCreditCard: ->
    card = @get 'card'
    @set 'changeCreditCardDialog', AIO.ChangeCreditCardDialog.create(card: card)

  cancelSubscription: ->
    billingProfile = AIO.get 'billingProfile'
    @set 'cancelingSubscription', true
    if window.confirm "Are you sure you want to cancel your subscription? You might end up losing access to your boxes."
      billingProfile.cancel (error) =>
        @set 'cancelingSubscription', false
        if error
          AIO.set 'flashMessage', { type: 'alert-error', text: error }
