App.BackwardsCompatibleRouter = Em.Object.extend
  transitionTo: ->
    router = App.Router.router
    router.transitionTo.apply(router, arguments)

  n2oBonusController: (->
    @getController 'n2o-bonus'
  ).property()

  getController: (name) ->
    App.__container__.lookup("controller:#{name}")

App.set 'router', App.BackwardsCompatibleRouter.create()
