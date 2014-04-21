App.BoxResourcesRoute = Em.Route.extend
  activate: ->
    App.get('currentUser').fetchN2O()

  deactivate: ->
    @controller.set 'content', null
