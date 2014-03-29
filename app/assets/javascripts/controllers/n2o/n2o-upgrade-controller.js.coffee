AIO.N2oUpgradeController = Em.Controller.extend
  subscriptionBinding: 'AIO.subscription'

  card: null
  selectedPlan: null
  stripeToken: null

  processing: false
  processingErrorMessage: null
  confirmUpgradeDialog: null

  initialize: ->
    this.reset()

    @set 'card', AIO.CreditCard.create()
    @set 'selectedPlan', AIO.Plan.personalPlans.findProperty('highlight', true)

    AIO.util.mixpanel 'Viewed N2O Upgrade Page'

  reset: ->
    @set 'processing', false
    @set 'processingErrorMessage', null
    @set 'currentPlan', null
    @set 'confirmUpgradeDialog', null
    @set 'stripeToken', null

  discount: (->
    coupon = AIO.currentUser.get('coupon')
    return 0 unless coupon

    percentOff = coupon.percent_off
    selectedPlanPrice = @get('selectedPlan').get('price')

    selectedPlanPrice * ( percentOff / 100 )
  ).property 'AIO.currentUser.coupon', 'selectedPlan'

  total: (->
    selectedPlanPrice = @get('selectedPlan').get('price')
    selectedPlanPrice - @get('discount')
  ).property 'selectedPlan', 'discount'

  displayN2OInfo: (->
    return AIO.get('boxes.length') == 0
  ).property 'AIO.boxes.length'

  upgrade: ->
    @set 'processing', true
    @set 'processingErrorMessage', null
    card = @get 'card'

    unless selectedPlan = @get 'selectedPlan'
      return

    card.createToken (error, stripeToken) =>
      if error
        @set 'processing', false
        this._setFormError error
      else
        @set 'stripeToken', stripeToken
        @set 'confirmUpgradeDialog', AIO.ConfirmUpgradeDialog.create plan: selectedPlan, total: @get('total')

  upgradeConfirmed: ->
    AIO.set 'currentUser.subscription_pending', true
    AIO.Subscription.subscribe @get('selectedPlan').get('id'), @get('stripeToken'), (error) => this._afterUpgrade(error)

  upgradeCanceled: ->
    @set 'processing', false
    @set 'stripeToken', null

  _afterUpgrade: (error) ->
    @set 'processing', false
    @set 'stripeToken', null
    if error
      this._setFormError error
      return

    @set 'processingErrorMessage', null
    Em.run.scheduleOnce 'afterRender', this, ->
      AIO.set 'flashMessage', { type: 'alert-success', text: 'We are processing your purchase, you should be receiving an email shortly with a receipt of purchase.' }

    if AIO.get('currentUser.intro_seen')
      AIO.get('router').transitionTo 'n2o.bonus'
    else
      AIO.get('router').transitionTo 'intro.index'

  _setFormError: (error) ->
    @set 'processingErrorMessage', error
