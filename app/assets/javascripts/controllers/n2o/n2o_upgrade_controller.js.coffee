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
    @set 'changingCard', !@get('billingProfile.active')

    # TODO: refactor once AIO.Model is merged
    AIO.SubscriptionPlan.fetchAll (err, models) =>
      @set 'plans', AIO.SubscriptionPlansCollection.create(content: Em.A(models))
      this._setSelectedPlan()

  processUpgrade: (token, callback) ->
    @set 'processing', true
    @set 'processingErrorMessage', null

    billingProfile = @get 'billingProfile'
    card = @get 'card'
    selectedPlan = @get 'selectedPlan'
    changingCard = @get 'changingCard'

    # if user did only change the plan, not the credit card
    # we do not need to fetch stripe token
    if billingProfile.get('exists') && !changingCard
      return billingProfile.upgrade selectedPlan, null, (error) => this._afterUpgrade(error)

    card.createToken (error, stripeToken) =>
      if error
        this._setFormError error
      else
        billingProfile.upgrade selectedPlan, stripeToken, (error) => this._afterUpgrade(error)

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
    AIO.set 'flashMessage', { type: 'notice', text: 'We are processing your purchase, you should be receiving an email shortly with a receipt of purchase.' }

  _setSelectedPlan: ->
    billingProfile = @get 'billingProfile'
    if billingProfile && (activeSubscriptionPlan = billingProfile.get 'activeSubscriptionPlan')
      selectedPlan = activeSubscriptionPlan.id
    else
      selectedPlan = @get('plans').objectAt(0).get('id')
    @set 'selectedPlan', selectedPlan
