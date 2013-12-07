AIO.AccountSettingsIndexController = Em.ObjectController.extend
  content: null
  card: null
  resettingPassword: false
  cancelingSubscription: false

  changeCreditCardDialog: null
  confirmCancelSubscriptionDialog: null

  initialize: ->
    @set 'content', AIO.get('currentUser')
    @set 'card', AIO.CreditCard.create()

  hasActiveSubscription: (->
    if subscription = AIO.get 'subscription'
      subscription.get 'active'
  ).property 'AIO.subscription.active'

  currentPlan: (->
    if subscription = AIO.get 'subscription'
      subscription.get('plan').get('name')
  ).property 'AIO.subscription.plan'

  currentCardDetails: (->
    if billingProfile = AIO.get 'billingProfile'
      formattedCardNumber = billingProfile.get('formatted_card_number')
      cardType = billingProfile.get('card_type')
      "#{formattedCardNumber} (#{cardType})"
  ).property 'AIO.billingProfile.formatted_card_number', 'AIO.billingProfile.card_type'

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

  confirmCancelSubscription: ->
    @set 'confirmCancelSubscriptionDialog', AIO.ConfirmCancelSubscriptionDialog.create()

  cancelSubscription: ->
    subscription = AIO.get 'subscription'
    @set 'cancelingSubscription', true
    subscription.cancel (error) =>
      @set 'cancelingSubscription', false
      if error
        AIO.set 'flashMessage', { type: 'alert-error', text: error }
      else
        subscription.set 'state', 'canceled'
        AIO.set 'flashMessage', { type: 'alert-info', text: 'Subscription canceled.' }
