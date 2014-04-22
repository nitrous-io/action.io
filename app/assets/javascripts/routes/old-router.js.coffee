App.RouterHelper = {}

App.Router = Em.Router.extend
  location: 'hash'

  root: Em.Route.extend
    boxes: Em.Route.extend
      route: '/boxes'

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
