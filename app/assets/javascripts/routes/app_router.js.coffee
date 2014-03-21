AIO.Router = Em.Router.extend
  location: 'hash'

  root: Em.Route.extend
    index: Em.Route.extend
      route: '/'
      redirectsTo: 'boxes.index'

    blank: Em.Route.extend
      route: '/blank'
      connectOutlets: (router) ->
        router.get('applicationController').connectOutlet 'blank'

    boxes: Em.Route.extend
      route: '/boxes'

      index: Em.Route.extend
        route: '/'
        connectOutlets: (router) ->
          unless AIO.get('currentUser.intro_seen') || AIO.get('currentUser.hasUsedN2O')
            AIO.get('router').transitionTo 'intro.index'
            return
          AIO.util.mixpanel 'Viewed Boxes Index'
          router.get('boxesController').findAll()
          router.get('applicationController').connectOutlet 'boxesIndex'

      new: Em.Route.extend
        route: '/new'
        connectOutlets: (router) ->
          AIO.util.mixpanel 'Viewed New Box'
          AIO.get('currentUser').fetchN2O()
          controller = router.get('boxesNewController')
          controller.set 'isIntro', false
          controller.newRecord()
          router.get('snapshotsController').findAll()
          router.get('applicationController').connectOutlet 'boxesNew'

      provisioning: Em.Route.extend
        route: '/:id/provisioning'
        connectOutlets: (router, context) ->
          AIO.util.mixpanel 'Viewed Box Provisioning', box_id: context.id
          controller = router.get 'boxesProvisioningController'
          router.get('boxesController').findResource parseInt(context.id, 10), (resource) ->
            controller.set 'content', resource
          router.get('applicationController').connectOutlet 'boxesProvisioning'
        exit: (router) ->
          router.get('boxesProvisioningController').set 'content', null

      ide: Em.Route.extend
        route: '/:id/ide'
        connectOutlets: (router, context) ->
          AIO.util.mixpanel 'IDE Session Started', box_id: context.id
          AIO.util.mixpanelIncrement 'ide_session_started_count'

          controller = router.get 'ideController'
          router.get('boxesController').findResource parseInt(context.id, 10), (resource) ->
            controller.set 'content', resource
          router.get('applicationController').connectOutlet 'ide'
        enter: (router) ->
          # warn the user before actually unload the window. This is helpful to
          # prevent mis-click close tab / cmd + w
          $(window).bind 'beforeunload.ide', ->
            "Remember to save all changes before closing the editor"
        exit: (router) ->
          $(window).unbind 'beforeunload.ide'
          router.get('ideController').reset()

      terminal: Em.Route.extend
        route: '/:id/terminal'
        connectOutlets: (router, context) ->
          AIO.util.mixpanel 'Web Terminal Started', box_id: context.id
          AIO.util.mixpanelIncrement 'web_terminal_started_count'

          controller = router.get 'ideController'
          router.get('boxesController').findResource parseInt(context.id, 10), (resource) ->
            controller.set 'content', resource
          router.get('applicationController').connectOutlet
            controller: router.get 'ideController'
            viewClass: AIO.IdeTerminalView
        enter: (router) ->
          # warn the user before actually unload the window. This is helpful to
          # prevent mis-click close tab / cmd + w
          $(window).bind 'beforeunload.ide', ->
            "Remember to save all changes before closing the editor"
        exit: (router) ->
          $(window).unbind 'beforeunload.ide'
          router.get('ideController').reset()

      resources: Em.Route.extend
        route: '/:id/edit/resources'
        connectOutlets: (router, context) ->
          AIO.util.mixpanel 'Viewed Box Edit', box_id: context.id
          AIO.get('currentUser').fetchN2O()
          controller = router.get 'resourcesEditController'
          router.get('boxesController').findResource parseInt(context.id, 10), (resource) ->
            controller.set 'content', resource
          router.get('applicationController').connectOutlet 'resourcesEdit'

      domains: Em.Route.extend
        route: '/:id/edit/domains'
        connectOutlets: (router, context) ->
          allowed = false
          router.get('boxesController').findResource parseInt(context.id, 10), (box) ->
            allowed = true
            AIO.util.mixpanel 'Viewed Custom Domains', box_id: context.id
            controller = router.get('domainsEditController')
            controller.set 'content', box
          if allowed
            router.get('applicationController').connectOutlet 'domainsEdit'

      # FIXME When we update Ember, use nested resources instead.
      snapshotsIndex: Em.Route.extend
        route: '/:id/edit/snapshots'
        connectOutlets: (router, context) ->
          unless AIO.get('currentUser.box_snapshots_allowed')
            AIO.get('router').transitionTo 'boxes.index'
            return
          controller = router.get('snapshotsIndexController')
          router.get('snapshotsController').findAll()
          router.get('boxesController').findResource parseInt(context.id, 10), (box) ->
            controller.set 'box', box
          router.get('applicationController').connectOutlet 'snapshotsIndex'

      # FIXME When we update Ember, use nested resources instead.
      snapshotsNew: Em.Route.extend
        route: '/:id/edit/snapshots/new'
        connectOutlets: (router, context) ->
          unless AIO.get('currentUser.box_snapshots_allowed')
            AIO.get('router').transitionTo 'boxes.index'
            return
          controller = router.get('snapshotsNewController')
          router.get('boxesController').findResource parseInt(context.id, 10), (box) ->
            controller.newRecord(box)
          router.get('applicationController').connectOutlet 'snapshotsNew'

    publicKeys: Em.Route.extend
      route: '/public_keys'

      index: Em.Route.extend
        route: '/'
        connectOutlets: (router) ->
          AIO.util.mixpanel 'Viewed Public Keys Index'
          router.get('publicKeysController').findAll()
          router.get('applicationController').connectOutlet 'publicKeysIndex'

      new: Em.Route.extend
        route: '/new'
        connectOutlets: (router) ->
          AIO.util.mixpanel 'Viewed Public Keys New'
          router.get('publicKeysNewController').newRecord()
          router.get('applicationController').connectOutlet 'publicKeysNew'

    vagrant: Em.Route.extend
      route: '/vagrant'

      index: Em.Route.extend
        route: '/'
        connectOutlets: (router) ->
          AIO.util.mixpanel 'Viewed Vagrant Settings Page'
          router.get('vagrantIndexController').reset()
          router.get('applicationController').connectOutlet 'vagrantIndex'

    invites: Em.Route.extend
      route: '/invites'

      index: Em.Route.extend
        route: '/'
        connectOutlets: (router) ->
          AIO.util.mixpanel 'Viewed Invites Page'
          router.get('invitesController').findAll()
          router.get('applicationController').connectOutlet 'invitesIndex'

    n2o: Em.Route.extend
      route: '/n2o'

      index: Em.Route.extend
        route: '/'
        redirectsTo: 'n2o.bonus'

      bonus: Em.Route.extend
        route: '/bonus'
        connectOutlets: (router) ->
          AIO.util.mixpanel 'Viewed N2O Bonus Page'
          router.get('n2oBonusController').setProperties(isIntro: false).reload()
          router.get('applicationController').connectOutlet 'n2oBonus'

      upgrade: Em.Route.extend
        route: '/upgrade'
        connectOutlets: (router) ->
          AIO.util.mixpanel 'Viewed N2O Upgrade Page'
          router.get('n2oUpgradeController').initialize()
          router.get('applicationController').connectOutlet 'n2oUpgrade'

      change_plan: Em.Route.extend
        route: '/change_plan'
        connectOutlets: (router) ->
          AIO.util.mixpanel 'Viewed Change Plan Page'
          router.get('n2oChangePlanController').initialize()
          router.get('applicationController').connectOutlet 'n2oChangePlan'

    accountSettings: Em.Route.extend
      route: '/account_settings'

      index: Em.Route.extend
        route: '/'
        connectOutlets: (router) ->
          AIO.util.mixpanel 'Viewed Account Settings Page'
          router.get('accountSettingsIndexController').initialize()
          router.get('applicationController').connectOutlet 'accountSettingsIndex'

    intro: Em.Route.extend
      route: '/intro'

      index: Em.Route.extend
        route: '/'
        redirectsTo: 'intro.create'

      create: Em.Route.extend
        route: '/create'
        connectOutlets: (router) ->
          AIO.util.mixpanel 'Viewed Intro Create Box Page'
          AIO.get('currentUser').fetchN2O()
          controller = router.get('boxesNewController')
          controller.set 'isIntro', true
          controller.newRecord()
          router.get('applicationController').connectOutlet
            controller: controller
            viewClass: AIO.IntroCreateBoxView

      n2o: Em.Route.extend
        route: '/n2o'
        connectOutlets: (router, context) ->
          AIO.util.mixpanel 'Viewed Intro Earn N2O Page'
          controller = router.get 'introN2oController'
          box = router.get('boxesController.content.lastObject')
          controller.set 'content', box
          router.get('applicationController').connectOutlet
            controller: controller
            viewClass: AIO.IntroN2oView
          controller.connectOutlet
            outletName: 'n2oBonus'
            controller: router.get('n2oBonusController').setProperties(isIntro: true)
            viewClass: AIO.N2oBonusView

      apps: Em.Route.extend
        route: '/apps'
        connectOutlets: (router, context) ->
          AIO.util.mixpanel 'Viewed Intro Desktop Apps Page'
          controller = router.get 'introAppsController'
          box = router.get('boxesController.content.lastObject')
          controller.set 'content', box
          router.get('applicationController').connectOutlet
            controller: controller
            viewClass: AIO.IntroAppsView

      introOne: Em.Route.extend
        route: '/1'
        connectOutlets: (router) ->
          AIO.util.mixpanel 'Viewed Intro Screen 1'
          router.get('applicationController').connectOutlet
            controller: router.get 'introController'
            viewClass: AIO.IntroOneView

      introTwo: Em.Route.extend
        route: '/2'
        connectOutlets: (router) ->
          AIO.util.mixpanel 'Viewed Intro Screen 2'
          router.get('applicationController').connectOutlet
            controller: router.get 'introController'
            viewClass: AIO.IntroTwoView

      introThree: Em.Route.extend
        route: '/3'
        connectOutlets: (router) ->
          AIO.util.mixpanel 'Viewed Intro Screen 3'
          router.get('applicationController').connectOutlet
            controller: router.get 'introController'
            viewClass: AIO.IntroThreeView

      introFour: Em.Route.extend
        route: '/4'
        connectOutlets: (router) ->
          AIO.util.mixpanel 'Viewed Intro Screen 4'
          router.get('applicationController').connectOutlet
            controller: router.get 'introController'
            viewClass: AIO.IntroFourView

      introFive: Em.Route.extend
        route: '/5'
        connectOutlets: (router) ->
          AIO.util.mixpanel 'Viewed Intro Screen 5'
          router.get('applicationController').connectOutlet
            controller: router.get 'introController'
            viewClass: AIO.IntroFiveView
