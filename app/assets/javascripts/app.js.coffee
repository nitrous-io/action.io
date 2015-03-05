#= require zeroclipboard/ZeroClipboard
#= require ./zeroclipboard-path
#= require mousetrap
#= require codemirror
#= require firepad
#= require base64
#= require strftime
#= require jquery.ui.widget
#= require jquery.fileupload
#= require ua-parser
#= require ember-bootstrap
#= require shareable
#= require jquery.payment
#= require gh3
#= require_self
#= require app-classes

window.NitrousIO = Em.Application.extend Em.Evented,
  rootElement: '#app'

  config: null

  online: if !Em.isNone(window.navigator.onLine) then window.navigator.onLine else true
  offline: Em.computed.not 'online'

  flashMessage: null
  shoverSocket: null

  currentUser: null
  billingProfile: null
  subscription: null
  entryCouponCode: null

  publicKeys: (->
    App.PublicKey.all()
  ).property()

  boxes: (->
    App.Box.all()
  ).property()

  snapshots: (->
    App.Snapshot.all()
  ).property()

  boxTemplates: (->
    App.BoxTemplate.all()
  ).property()

  regions: (->
    App.Region.all()
  ).property()

  repositories: (->
    App.Repository.all()
  ).property()

  invites: (->
    App.Invite.all()
  ).property()

  bonus: null
  bonusInfo: null
  closestRegionId: null

  bootstrap: (config={}, data={}) ->
    @set 'config', App.Config.create(config)

    switch App.get('config.environment')
      when 'production'
        # disable deprecation and warning messages in production
        Em.deprecate = Em.K
        Em.warn = Em.K
      when 'development'
        @set 'LOG_RESOLVER', true
        @set 'LOG_TRANSITIONS', true
        @set 'LOG_TRANSITIONS_INTERNAL', true
        @set 'LOG_VIEW_LOOKUPS', true

    if currentUserHash = data.currentUser
      @set 'currentUser', currentUser = App.CurrentUser.create()

      if billingProfileHash = currentUserHash.billing_profile
        delete currentUserHash.billing_profile
        @set 'billingProfile', billingProfile = App.BillingProfile.create()
        billingProfile.loadHash billingProfileHash

      if subscriptionHash = currentUserHash.subscription
        delete currentUserHash.subscription
        @set 'subscription', subscription = App.Subscription.create()
        subscription.loadHash subscriptionHash

      currentUser.loadHash currentUserHash

    if entryCouponCodeHash = data.entryCouponCode
      @set 'entryCouponCode', entryCouponCodeHash

    if stripePublishableKey = @get 'config.stripePublishableKey'
      Stripe.setPublishableKey stripePublishableKey

    App.util.mixpanelIdentifyUser()

    if shoverServerURI = @get 'config.shoverServerURI'
      App.set 'shoverSocket', shoverSocket = App.ShoverSocket.create(serverURI: shoverServerURI)
      shoverSocket.connect()

    App.Region.preload(data.regions ? [])
    App.PublicKey.preload(data.publicKeys ? [])
    App.Plan.preload(data.plans ? [])

    allPlans = App.Plan.all()
    App.Plan.personalPlans = App.Plan.Collection.create(content: (data.personalPlanIds ? []).map (id) -> App.Plan.findById(id))
    App.Plan.teamPlans = App.Plan.Collection.create(content: (data.teamPlanIds ? []).map (id) -> App.Plan.findById(id))

    App.BoxTemplate.preload(data.boxTemplates ? [])
    App.Box.preload(data.boxes ? [])
    App.Snapshot.preload(data.snapshots ? [])
    App.Repository.preload(data.repositories ? [])

    if bonusHash = data.bonus
      App.set('bonus', bonus = App.Bonus.create())
      bonus.loadHash bonusHash
    App.set('bonusInfo', data.bonusInfo ? {})

window.App = NitrousIO.create()

Em.TextSupport.reopen
  attributeBindings: ['readonly']

# HACK: silence bindAttr deprecation warning (bindAttrs are rendered by Hamlbars).
# Goes away when we can upgrade Hamlbars to 2.1+ or switch to HTMLbars/Emblem.
Em.Handlebars.registerHelper('bindAttr', Ember.Handlebars.helpers['bind-attr'])

# prevent file drops on the document causing browser to navigate away
$(document).bind 'drop dragover', (e) ->
  e.preventDefault()

# prevent esc from disconnecting websocket connection in firefox
$(window).keydown (e) ->
  e.preventDefault() if e.keyCode == 27

$(window).on 'message', (event) ->
  if event.originalEvent.data == "chromeWebView"
    window.App?.set? 'isChromeWebView', true
    $('#install-chrome-app').hide()

$(window).on 'offline', ->
  window.App?.set? 'online', false

$(window).on 'online', ->
  window.App?.set? 'online', true
