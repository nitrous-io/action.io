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
          unless AIO.get 'currentUser.intro_seen'
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
          router.get('boxesNewController').newRecord()
          router.get('applicationController').connectOutlet 'boxesNew'

      edit: Em.Route.extend
        route: '/:id/edit'
        connectOutlets: (router, context) ->
          AIO.util.mixpanel 'Viewed Box Edit', box_id: context.id
          AIO.get('currentUser').fetchN2O()
          controller = router.get 'boxesEditController'
          router.get('boxesController').findResource parseInt(context.id, 10), (resource) ->
            controller.set 'content', resource
          router.get('applicationController').connectOutlet 'boxesEdit'

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
          router.get('n2oBonusController').reload()
          router.get('applicationController').connectOutlet 'n2oBonus'

    lightning: Em.Route.extend
      route: '/lightning'

      index: Em.Route.extend
        route: '/'
        redirectsTo: 'lightning.create'

      create: Em.Route.extend
        route: '/create'
        connectOutlets: (router) ->
          AIO.util.mixpanel 'Viewed Lightning Intro Create Box Page'
          AIO.get('currentUser').fetchN2O()
          controller = router.get('boxesNewController')
          controller.newRecord()
          controller.set 'isLightningMode', true
          router.get('applicationController').connectOutlet
            controller: controller
            viewClass: AIO.LightningCreateView

      github: Em.Route.extend
        route: '/github'
        connectOutlets: (router) ->
          AIO.util.mixpanel 'Viewed Lightning Intro GitHub Page'

    intro: Em.Route.extend
      route: '/intro'

      index: Em.Route.extend
        route: '/'
        redirectsTo: 'intro.introOne'

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
