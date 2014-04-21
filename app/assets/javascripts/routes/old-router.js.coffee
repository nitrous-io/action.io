App.RouterHelper = Em.Object.extend()
App.RouterHelper.reopenClass
  ideEnter: (router) ->
    # warn the user before actually unload the window. This is helpful to
    # prevent mis-click close tab / cmd + w
    $(window).bind 'beforeunload.ide', ->
      "Remember to save all changes before closing the editor"

  ideExit: (router) ->
    $(window).unbind 'beforeunload.ide'
    router.get('ideController').reset()

App.Router = Em.Router.extend
  location: 'hash'

  root: Em.Route.extend
    index: Em.Route.extend
      route: '/'
      redirectsTo: 'boxes.index'

    boxes: Em.Route.extend
      route: '/boxes'

      clone_repo_picker: Em.Route.extend
        route: '/clone_repo_picker'
        connectOutlets: (router, context) ->
          App.util.mixpanel 'Viewed Box Picker for Cloning Repo'
          App.util.saveReturnTo('boxes.clone_repo_picker')
          controller = router.get 'boxesCloneRepoPickerController'
          controller.newRecord()
          router.get('applicationController').connectOutlet 'boxesCloneRepoPicker'

      cloning_repo: Em.Route.extend
        route: '/:id/cloning_repo/:repo_id'
        connectOutlets: (router, context) ->
          App.util.mixpanel 'Viewed Box Cloning Repo Progress', box_id: context.id
          controller = router.get 'boxesCloningRepoController'
          box = App.Box.findById parseInt(context.id, 10)
          repository = App.Repository.findById parseInt(context.repo_id, 10)
          controller.set 'content', box
          controller.set 'repository', repository
          router.get('applicationController').connectOutlet 'boxesCloningRepo'
        exit: (router) ->
          router.get('boxesCloningRepoController').set 'content', null

      ide: Em.Route.extend
        route: '/:id/ide'
        connectOutlets: (router, context) ->
          App.util.mixpanel 'IDE Session Started', box_id: context.id
          App.util.mixpanelIncrement 'ide_session_started_count'

          controller = router.get 'ideController'
          box = App.Box.findById parseInt(context.id, 10)
          controller.set 'content', box
          router.get('applicationController').connectOutlet 'ide'
        enter: App.RouterHelper.ideEnter
        exit: App.RouterHelper.ideExit

      ide_with_repo: Em.Route.extend
        route: '/:id/ide/:repo_id'
        connectOutlets: (router, context) ->
          App.util.mixpanel 'IDE Session Started', box_id: context.id
          App.util.mixpanelIncrement 'ide_session_started_count'

          controller = router.get 'ideController'
          box = App.Box.findById parseInt(context.id, 10)
          repository = App.Repository.findById parseInt(context.repo_id, 10)
          controller.set 'content', box
          controller.set 'repository', repository
          router.get('applicationController').connectOutlet 'ide'
        enter: App.RouterHelper.ideEnter
        exit: App.RouterHelper.ideExit

      terminal: Em.Route.extend
        route: '/:id/terminal'
        connectOutlets: (router, context) ->
          App.util.mixpanel 'Web Terminal Started', box_id: context.id
          App.util.mixpanelIncrement 'web_terminal_started_count'

          controller = router.get 'ideController'
          box = App.Box.findById parseInt(context.id, 10)
          controller.set 'content', box
          router.get('applicationController').connectOutlet
            controller: router.get 'ideController'
            viewClass: App.IdeTerminalView
        enter: App.RouterHelper.ideEnter
        exit: App.RouterHelper.ideExit

    publicKeys: Em.Route.extend
      route: '/public_keys'

      index: Em.Route.extend
        route: '/'
        connectOutlets: (router) ->
          App.util.mixpanel 'Viewed Public Keys Index'
          App.PublicKey.all().reload()
          router.get('applicationController').connectOutlet 'publicKeysIndex'

      new: Em.Route.extend
        route: '/new'
        connectOutlets: (router) ->
          App.util.mixpanel 'Viewed Public Keys New'
          router.set 'publicKeysNewController.content', App.PublicKey.create()
          router.get('applicationController').connectOutlet 'publicKeysNew'

    vagrant: Em.Route.extend
      route: '/vagrant'

      index: Em.Route.extend
        route: '/'
        connectOutlets: (router) ->
          App.util.mixpanel 'Viewed Vagrant Settings Page'
          router.get('vagrantIndexController').reset()
          router.get('applicationController').connectOutlet 'vagrantIndex'

    invites: Em.Route.extend
      route: '/invites'

      index: Em.Route.extend
        route: '/'
        connectOutlets: (router) ->
          App.util.mixpanel 'Viewed Invites Page'
          App.Invite.all().reload()
          router.set 'invitesIndexController.newInvite', App.Invite.create()
          router.get('applicationController').connectOutlet 'invitesIndex'

    n2o: Em.Route.extend
      route: '/n2o'

      index: Em.Route.extend
        route: '/'
        redirectsTo: 'n2o.bonus'

      bonus: Em.Route.extend
        route: '/bonus'
        connectOutlets: (router) ->
          App.util.mixpanel 'Viewed N2O Bonus Page'
          router.get('n2oBonusController').setProperties(isIntro: false).reload()
          router.get('applicationController').connectOutlet 'n2oBonus'

      upgrade: Em.Route.extend
        route: '/upgrade'
        connectOutlets: (router) ->
          if App.get('currentUser.aws_activate_plans_enabled')
            App.util.mixpanel 'Viewed N2O Upgrade Page', aws_activate: true
          else
            App.util.mixpanel 'Viewed N2O Upgrade Page'
          router.get('n2oUpgradeController').initialize()
          router.get('applicationController').connectOutlet 'n2oUpgrade'

      change_plan: Em.Route.extend
        route: '/change_plan'
        connectOutlets: (router) ->
          App.util.mixpanel 'Viewed Change Plan Page'
          router.get('n2oChangePlanController').initialize()
          router.get('applicationController').connectOutlet 'n2oChangePlan'

    accountSettings: Em.Route.extend
      route: '/account_settings'

      index: Em.Route.extend
        route: '/'
        connectOutlets: (router) ->
          App.util.mixpanel 'Viewed Account Settings Page'
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
          App.util.mixpanel 'Viewed Intro Create Box Page'
          App.get('currentUser').fetchN2O()
          controller = router.get('boxesNewController')
          controller.set 'isIntro', true
          controller.newRecord()
          router.get('applicationController').connectOutlet
            controller: controller
            viewClass: App.IntroCreateBoxView

      n2o: Em.Route.extend
        route: '/n2o'
        connectOutlets: (router, context) ->
          App.util.mixpanel 'Viewed Intro Earn N2O Page'
          controller = router.get 'introN2oController'
          box = App.get('boxes.lastObject')
          controller.set 'content', box
          router.get('applicationController').connectOutlet
            controller: controller
            viewClass: App.IntroN2oView
          controller.connectOutlet
            outletName: 'n2oBonus'
            controller: router.get('n2oBonusController').setProperties(isIntro: true)
            viewClass: App.N2oBonusView

      apps: Em.Route.extend
        route: '/apps'
        connectOutlets: (router, context) ->
          App.util.mixpanel 'Viewed Intro Desktop Apps Page'
          controller = router.get 'introAppsController'
          box = App.get('boxes.lastObject')
          controller.set 'content', box
          router.get('applicationController').connectOutlet
            controller: controller
            viewClass: App.IntroAppsView

      introOne: Em.Route.extend
        route: '/1'
        connectOutlets: (router) ->
          App.util.mixpanel 'Viewed Intro Screen 1'
          router.get('applicationController').connectOutlet
            controller: router.get 'introController'
            viewClass: App.IntroOneView

      introTwo: Em.Route.extend
        route: '/2'
        connectOutlets: (router) ->
          App.util.mixpanel 'Viewed Intro Screen 2'
          router.get('applicationController').connectOutlet
            controller: router.get 'introController'
            viewClass: App.IntroTwoView

      introThree: Em.Route.extend
        route: '/3'
        connectOutlets: (router) ->
          App.util.mixpanel 'Viewed Intro Screen 3'
          router.get('applicationController').connectOutlet
            controller: router.get 'introController'
            viewClass: App.IntroThreeView

      introFour: Em.Route.extend
        route: '/4'
        connectOutlets: (router) ->
          App.util.mixpanel 'Viewed Intro Screen 4'
          router.get('applicationController').connectOutlet
            controller: router.get 'introController'
            viewClass: App.IntroFourView

      introFive: Em.Route.extend
        route: '/5'
        connectOutlets: (router) ->
          App.util.mixpanel 'Viewed Intro Screen 5'
          router.get('applicationController').connectOutlet
            controller: router.get 'introController'
            viewClass: App.IntroFiveView
