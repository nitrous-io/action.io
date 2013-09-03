AIO.N2oUpgradeController = Em.ObjectController.extend
  card: null
  plans: null
  selectedPlan: null

  init: ->
    @set 'card', AIO.CreditCard.create()
    # TODO: refactor once AIO.Model is merged
    AIO.SubscriptionPlan.fetchAll (err, models) =>
      @set 'plans', AIO.SubscriptionPlansCollection.create(content: Em.A(models))
      this._setSelectedPlan()

  createSubscription: (token, callback) ->
    $.ajax(
      url: '/subscription'
      type: 'post'
      data: { plan_id: @get('selectedPlan'), stripe_token: token }
    ).done((json) =>
      callback()
    ).fail (xhr, textStatus, error) =>
      errors = JSON.parse xhr.responseText
      errorMessage = errors.base
      callback errorMessage

  _setSelectedPlan: ->
    billingProfile = AIO.get 'billingProfile'
    if billingProfile
    @set 'selectedPlan', @get('plans').objectAt(0).get('id')
