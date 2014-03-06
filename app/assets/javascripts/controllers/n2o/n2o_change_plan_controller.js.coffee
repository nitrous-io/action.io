AIO.N2oChangePlanController = Em.Controller.extend
  personalPlansBinding: 'AIO.router.plansController'
  subscriptionBinding: 'AIO.subscription'

  selectedPlan: null
  currentPlan: null

  processing: false
  processingErrorMessage: null
  changeCreditCardDialog: null

  card: null

  initialize: ->
    this.reset()

    plan = @get('subscription').get('plan')
    @set 'selectedPlan', plan
    @set 'currentPlan', plan

    if AIO.get('entryCouponCode')
      AIO.set 'flashMessage', { type: 'alert-error', text: "Coupons can only be used by new users who haven't already subscribed to a plan." }
      AIO.set('entryCouponCode', null)

  reset: ->
    @set 'processing', false
    @set 'processingErrorMessage', null

  changePlan: (callback) ->
    @set 'processing', true
    @set 'processingErrorMessage', null

    if selectedPlan = @get 'selectedPlan'
      return @get('subscription').changePlan selectedPlan.get('id'), (error) => this._afterUpgrade(error)

  changeCreditCard: ->
    @set 'card', AIO.CreditCard.create()
    @set 'changeCreditCardDialog', AIO.ChangeCreditCardDialog.create(card: @get('card'))

  _afterUpgrade: (error) ->
    @set 'processing', false
    if error
      this._setFormError error
    else
      AIO.set 'currentUser.subscription_pending', true
      this._redirectToBonusPage()

  _setFormError: (error) ->
    @set 'processingErrorMessage', error

  _redirectToBonusPage: ->
    @set 'processingErrorMessage', null
    Em.run.scheduleOnce 'afterRender', this, '_showFlashMessage'
    AIO.get('router').transitionTo 'n2o.bonus'

  _showFlashMessage: ->
    AIO.set 'flashMessage', { type: 'alert-success', text: 'We are processing your purchase, you should be receiving an email shortly with a receipt of purchase.' }
