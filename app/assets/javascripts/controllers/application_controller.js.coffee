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

      if subscription = AIO.get('currentUser').get('subscription')
        AIO.set 'subscription', AIO.Subscription.create(subscription)

    if entryCouponCode = options.entryCouponCode
      AIO.set 'entryCouponCode', entryCouponCode

    if abTestAlternatives = options.abTestAlternatives
      AIO.set 'abTestAlternatives', abTestAlternatives
      mixpanel?.register abTestAlternatives

    if stripePublishableKey = options.stripePublishableKey
      Stripe.setPublishableKey stripePublishableKey

    [
      'shoverServerURI'
      'firebaseHost'
      'n2o128mbMemory'
      'n2o250mbStorage'
      'paymentsEnabled'
      'maxMemoryGB'
      'maxStorageGB'
    ].forEach (name) ->
      if val = options[name]
        AIO.set name, val

    AIO.util.mixpanelIdentifyUser()
    AIO.set 'flashMessage', null

    if shoverServerURI = options.shoverServerURI
      AIO.set 'shoverSocket', shoverSocket = AIO.ShoverSocket.create()
      shoverSocket.connect()
