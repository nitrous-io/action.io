AIO.AccountSettingsIndexController = Em.ObjectController.extend
  content: null
  resettingPassword: false

  changeCreditCardDialog: null
  card: null

  init: ->
    @_super()
    @set 'content', AIO.get('currentUser')
    @set 'card', AIO.CreditCard.create()

  currentPlanName: (->
    billingProfile = AIO.get 'billingProfile'
    activeSubscriptionPlan = billingProfile.get 'activeSubscriptionPlan'
    activeSubscriptionPlan.name
  ).property 'AIO.billingProfile'

  currentCardDetails: (->
    billingProfile = AIO.get 'billingProfile'
    formattedCardNumber = billingProfile.get('formatted_card_number')
    cardType = billingProfile.get('card_type')
    "#{formattedCardNumber} (#{cardType})"
  ).property 'AIO.billingProfile'

  resetPassword: ->
    @set 'resettingPassword', true
    record = @get 'content'
    record.resetPassword()
          .done ->
            AIO.set 'flashMessage', { type: 'notice', text: 'You should receive an email with instructions to reset the password.' }
          .always ->
            @set 'resettingPassword', false

  updateProfile: ->
    record = @get 'content'
    record.set 'errors', null
    record.updateInfo()
          .done ->
            AIO.set 'flashMessage', { type: 'notice', text: 'Your account details were updated successfully.' }

  changeCreditCard: ->
    card = @get 'card'
    @set 'changeCreditCardDialog', AIO.ChangeCreditCardDialog.create(card: card)
