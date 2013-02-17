AIO.IndexRoute = Em.Route.extend
  redirect: ->
    this.transitionTo 'boxes'

