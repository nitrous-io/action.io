App.BackwardsCompatibleRouter = Em.Object.extend
  transitionTo: ->
    router = App.Router.router
    router.transitionTo.apply(router, arguments)

App.set 'router', App.BackwardsCompatibleRouter.create()
