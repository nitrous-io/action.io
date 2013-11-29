AIO.ApplicationController = Em.Controller.extend
  currentUser: null
  billingProfile: null

  initialize: (options={}) ->
    if environment = options.environment
      AIO.set 'environment', environment

    if currentUser = options.currentUser
      AIO.set 'currentUser', AIO.User.create(currentUser.user)

      if billingProfile = AIO.get('currentUser').get('billing_profile')
        AIO.set 'billingProfile', AIO.BillingProfile.create(billingProfile)

    if pusherKey = options.pusherKey
      AIO.get('router.pusherController').initialize pusherKey

    if stripePublishableKey = options.stripePublishableKey
      Stripe.setPublishableKey stripePublishableKey

    [
      'firebaseHost'
      'n2o128mbMemory'
      'n2o250mbStorage'
      'paymentsEnabled'
    ].forEach (name) ->
      if val = options[name]
        AIO.set name, val

    AIO.util.mixpanelIdentifyUser()
    AIO.set 'flashMessage', null
