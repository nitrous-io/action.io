AIO.N2oUpgradeController = Em.ObjectController.extend
  billingProfile: null
  plans: null

  card: null
  selectedPlan: null
  currentPlan: null

  captureCard: false
  processing: false
  processingErrorMessage: null

  init: ->
    billingProfile = AIO.get('billingProfile') || AIO.BillingProfile.create()
    @set 'billingProfile', billingProfile
    @set 'card', AIO.CreditCard.create()

    # TODO: refactor once AIO.Model is merged
    AIO.SubscriptionPlan.fetchAll (err, models) =>
      @set 'plans', AIO.SubscriptionPlansCollection.create(content: Em.A(models))
      this._setSelectedPlan()

    @set 'processing', false
    @set 'processingErrorMessage', null
    @set 'captureCard', false

  processUpgrade: (token, callback) ->
    @set 'processing', true
    @set 'processingErrorMessage', null

    billingProfile = @get 'billingProfile'
    card = @get 'card'
    selectedPlan = @get 'selectedPlan'
    captureCard = @get 'captureCard'

    # if user did only change the plan, not the credit card
    # we do not need to fetch stripe token
    if billingProfile.get('active') && !captureCard
      return billingProfile.upgrade selectedPlan?.get('id'), null, (error) => this._afterUpgrade(error)

    card.createToken (error, stripeToken) =>
      if error
        this._setFormError error
      else
        billingProfile.upgrade selectedPlan?.get('id'), stripeToken, (error) => this._afterUpgrade(error)

  _afterUpgrade: (error) ->
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
    Em.run.scheduleOnce 'afterRender', this, '_showFlashMessage'
    AIO.get('router').transitionTo 'n2o.bonus'

  _showFlashMessage: ->
    AIO.set 'flashMessage', { type: 'alert-success', text: 'We are processing your purchase, you should be receiving an email shortly with a receipt of purchase.' }

  _setSelectedPlan: ->
    billingProfile = @get 'billingProfile'
    if billingProfile && (activeSubscriptionPlan = billingProfile.get 'activeSubscriptionPlan')
      selectedPlan = activeSubscriptionPlan
      @set 'currentPlan', selectedPlan
    else
      selectedPlan = @get('plans').objectAt(0)
    @set 'selectedPlan', selectedPlan
