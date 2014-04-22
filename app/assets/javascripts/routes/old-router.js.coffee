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

    intro: Em.Route.extend
      route: '/intro'

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
