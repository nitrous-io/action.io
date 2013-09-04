AIO.N2oUpgradeController = Em.ObjectController.extend
  billingProfile: null
  plans: null

  card: null
  selectedPlan: null

  changingCard: false
  processing: false
  processingErrorMessage: null

  init: ->
    @set 'billingProfile', (AIO.get('billingProfile') || AIO.BillingProfile.create())
    @set 'card', AIO.CreditCard.create()
    # TODO: refactor once AIO.Model is merged
    AIO.SubscriptionPlan.fetchAll (err, models) =>
      @set 'plans', AIO.SubscriptionPlansCollection.create(content: Em.A(models))
      this._setSelectedPlan()

  processUpgrade: (token, callback) ->
    @set 'processing', true
    @set 'processingErrorMessage', null

    billingProfile = @get 'billingProfile'
    selectedPlan = @get 'selectedPlan'
    changingCard = @get 'changingCard'

    # if user did only change the plan, not the credit card
    # we do not need to fetch stripe token
    if billingProfile.exists && changingCard
      billingProfile.upgrade selectedPlan, nil, this._afterUprade

    this._fetchStripeTokenForCreditCard (error, stripeToken) ->
      if error
        this._setFormError error
      else
        billingProfile.upgrade selectedPlan, stripeToken, this._afterUprade

  _fetchStripeTokenForCreditCard: (callback) ->
    card = controller.get 'card'
    if card.valid()
      card.createToken (status, response) =>
        if response.error
          callback response.error.message
        else
          callback null, response.id
    else
      callback 'Credit Card details you entered was invalid.'

  _afterUprade: (error) ->
    if error
      this._setFormError error
    else
      this._redirectToBonusPage()

  _setFormError: (error) ->
    @set 'processing', false
    @set 'processingErrorMessage', error

  _redirectToBonusPage: ->
    @set 'processing', false
    @set 'processingErrorMessage', null
    AIO.get('router').transitionTo 'n2o.bonus'

  _setSelectedPlan: ->
    billingProfile = @get 'billingProfile'
    if billingProfile && (activeSubscriptionPlan = billingProfile.get 'activeSubscriptionPlan')
      selectedPlan = activeSubscriptionPlan.id
    else
      selectedPlan = @get('plans').objectAt(0).get('id')
    @set 'selectedPlan', selectedPlan
