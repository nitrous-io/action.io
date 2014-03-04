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

    if stripePublishableKey = options.stripePublishableKey
      Stripe.setPublishableKey stripePublishableKey

    [
      'shoverServerURI'
      'firebaseHost'
      'n2o128mbMemory'
      'n2o250mbStorage'
      'paymentsEnabled'
      'maxMemoryMB'
      'maxStorageMB'
      'minMemoryMB'
      'minStorageMB'
    ].forEach (name) ->
      if val = options[name]
        AIO.set name, val

    AIO.util.mixpanelIdentifyUser()
    AIO.set 'flashMessage', null

    if maxMemoryMB = AIO.get('maxMemoryMB')
      AIO.set 'maxMemoryGB', maxMemoryMB / 1024

    if maxStorageMB = AIO.get('maxStorageMB')
      AIO.set 'maxStorageGB', maxStorageMB / 1000

    if shoverServerURI = options.shoverServerURI
      AIO.set 'shoverSocket', shoverSocket = AIO.ShoverSocket.create()
      shoverSocket.connect()
