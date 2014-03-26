AIO.ApplicationController = Em.Controller.extend
  initialize: (options={}) ->
    if environment = options.environment
      AIO.set 'environment', environment

    if currentUserHash = options.currentUser
      AIO.set 'currentUser', currentUser = AIO.CurrentUser.create()

      if billingProfileHash = currentUserHash.billing_profile
        delete currentUserHash.billing_profile
        AIO.set 'billingProfile', billingProfile = AIO.BillingProfile.create()
        billingProfile.loadHash billingProfileHash

      if subscriptionHash = currentUserHash.subscription
        delete currentUserHash.subscription
        AIO.set 'subscription', subscription = AIO.Subscription.create()
        subscription.loadHash subscriptionHash

      currentUser.loadHash currentUserHash

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

    AIO.BoxTemplate.preload(options.boxTemplates ? [])
    AIO.Region.preload(options.regions ? [])
    AIO.PublicKey.preload(options.publicKeys ? [])
    AIO.Plan.preload(options.plans ? [])

    allPlans = AIO.Plan.all()
    AIO.Plan.personalPlans = AIO.Plan.Collection.create(content: (options.personalPlanIds ? []).map (id) -> AIO.Plan.findById(id))
    AIO.Plan.teamPlans = AIO.Plan.Collection.create(content: (options.teamPlanIds ? []).map (id) -> AIO.Plan.findById(id))

    AIO.get('router.boxesController').loadAll(boxes: options.boxes ? [])
    AIO.get('router.snapshotsController').loadAll(snapshots: options.snapshots ? [])
    if bonusHash = options.bonus
      AIO.set('router.n2oBonusController.content', bonus = AIO.Bonus.create())
      bonus.loadHash bonusHash
    AIO.set('router.n2oBonusController.bonusInfo', options.bonusInfo ? {})
