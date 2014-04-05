App.ApplicationController = Em.Controller.extend
  initialize: (options={}) ->
    if environment = options.environment
      App.set 'environment', environment

    if currentUserHash = options.currentUser
      App.set 'currentUser', currentUser = App.CurrentUser.create()

      if billingProfileHash = currentUserHash.billing_profile
        delete currentUserHash.billing_profile
        App.set 'billingProfile', billingProfile = App.BillingProfile.create()
        billingProfile.loadHash billingProfileHash

      if subscriptionHash = currentUserHash.subscription
        delete currentUserHash.subscription
        App.set 'subscription', subscription = App.Subscription.create()
        subscription.loadHash subscriptionHash

      currentUser.loadHash currentUserHash

    if entryCouponCodeHash = options.entryCouponCode
      App.set 'entryCouponCode', entryCouponCodeHash

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
        App.set name, val

    App.util.mixpanelIdentifyUser()
    App.set 'flashMessage', null

    if maxMemoryMB = App.get('maxMemoryMB')
      App.set 'maxMemoryGB', maxMemoryMB / 1024

    if maxStorageMB = App.get('maxStorageMB')
      App.set 'maxStorageGB', maxStorageMB / 1000

    if shoverServerURI = options.shoverServerURI
      App.set 'shoverSocket', shoverSocket = App.ShoverSocket.create()
      shoverSocket.connect()

    App.Region.preload(options.regions ? [])
    App.PublicKey.preload(options.publicKeys ? [])
    App.Plan.preload(options.plans ? [])

    allPlans = App.Plan.all()
    App.Plan.personalPlans = App.Plan.Collection.create(content: (options.personalPlanIds ? []).map (id) -> App.Plan.findById(id))
    App.Plan.teamPlans = App.Plan.Collection.create(content: (options.teamPlanIds ? []).map (id) -> App.Plan.findById(id))

    App.BoxTemplate.preload(options.boxTemplates ? [])
    App.Box.preload(options.boxes ? [])
    App.Snapshot.preload(options.snapshots ? [])
    App.Repository.preload(options.repositories ? [])

    if bonusHash = options.bonus
      App.set('router.n2oBonusController.content', bonus = App.Bonus.create())
      bonus.loadHash bonusHash
    App.set('router.n2oBonusController.bonusInfo', options.bonusInfo ? {})
