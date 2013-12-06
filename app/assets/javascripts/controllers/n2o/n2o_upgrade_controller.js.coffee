AIO.N2oUpgradeController = Em.Controller.extend
  billingProfile: null
  plansBinding: 'AIO.router.plansController'
  subscriptionBinding: 'AIO.subscription'

  card: null
  selectedPlan: null
  currentPlan: null

  processing: false
  processingErrorMessage: null
  changeCreditCardDialog: null

  initialize: ->
    this.reset()

    billingProfile = AIO.get('billingProfile')

    # go back to index if upgrade currently in progress
    if billingProfile && billingProfile.get('transactionProcessing')
      Em.run.next ->
        AIO.get('router').transitionTo 'n2o.index'
        Em.run.scheduleOnce 'afterRender', this, ->
          AIO.set 'flashMessage', { type: 'alert-success', text: 'We are still processing your purchase, you should be receiving an email shortly with a receipt of purchase.' }

    @set 'billingProfile', ( billingProfile || AIO.BillingProfile.create() )
    @set 'card', AIO.CreditCard.create()

    subscription = @get 'subscription'
    if subscription && (currentPlan = subscription.get 'plan')
      selectedPlan = currentPlan
    else
      selectedPlan = @get('plans').findProperty('highlight', true)
    @set 'selectedPlan', selectedPlan
    @set 'currentPlan', currentPlan

  reset: ->
    @set 'processing', false
    @set 'processingErrorMessage', null

  processUpgrade: (token, callback) ->
    @set 'processing', true
    @set 'processingErrorMessage', null

    subscription = @get 'subscription'
    card = @get 'card'
    selectedPlan = @get 'selectedPlan'

    # when user is just changing the plan,
    # we need not to fetch the stripe token.
    if subscription.get('active')
      return billingProfile.upgrade selectedPlan?.get('id'), null, (error) => this._afterUpgrade(error)

    card.createToken (error, stripeToken) =>
      if error
        this._setFormError error
      else
        billingProfile.upgrade selectedPlan?.get('id'), stripeToken, (error) => this._afterUpgrade(error)

  changeCreditCard: ->
    card = @get 'card'
    @set 'changeCreditCardDialog', AIO.ChangeCreditCardDialog.create(card: card)

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
