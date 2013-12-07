AIO.N2oUpgradeController = Em.Controller.extend
  card: null
  selectedPlan: null

  processing: false
  processingErrorMessage: null

  plansBinding: 'AIO.router.plansController'
  subscriptionBinding: 'AIO.subscription'

  initialize: ->
    this.reset()
    @set 'card', AIO.CreditCard.create()
    @set 'selectedPlan', @get('plans').findProperty('highlight', true)

  reset: ->
    @set 'processing', false
    @set 'processingErrorMessage', null

  upgrade: ->
    @set 'processing', true
    @set 'processingErrorMessage', null

    card = @get 'card'
    selectedPlan = @get 'selectedPlan'

    card.createToken (error, stripeToken) =>
      if error
        @set 'processing', false
        this._setFormError error
      else
        AIO.Subscription.subscribe selectedPlan?.get('id'), stripeToken, (error) => this._afterUpgrade(error)

  _afterUpgrade: (error) ->
    @set 'processing', false
    if error
      this._setFormError error
    else
      this._redirectToBonusPage()

  _setFormError: (error) ->
    @set 'processingErrorMessage', error

  _redirectToBonusPage: ->
    @set 'processingErrorMessage', null
    Em.run.scheduleOnce 'afterRender', this, '_showFlashMessage'
    AIO.get('router').transitionTo 'n2o.bonus'

  _showFlashMessage: ->
    AIO.set 'flashMessage', { type: 'alert-success', text: 'We are processing your purchase, you should be receiving an email shortly with a receipt of purchase.' }
