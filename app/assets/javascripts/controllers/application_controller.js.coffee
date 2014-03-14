AIO.ApplicationController = Em.Controller.extend
  initialize: (options={}) ->
    if environment = options.environment
      AIO.set 'environment', environment

    if currentUserHash = options.currentUser
      AIO.set 'currentUser', currentUser = AIO.CurrentUser.create()
      currentUser.load currentUserHash.user.id, currentUserHash.user

      if billingProfileHash = AIO.get('currentUser').get('billing_profile')
        AIO.set 'billingProfile', AIO.BillingProfile.create(billingProfileHash)

      if subscriptionHash = AIO.get('currentUser').get('subscription')
        AIO.set 'subscription', AIO.Subscription.create(subscriptionHash)

    if entryCouponCodeHash = options.entryCouponCode
      AIO.set 'entryCouponCode', entryCouponCodeHash

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
