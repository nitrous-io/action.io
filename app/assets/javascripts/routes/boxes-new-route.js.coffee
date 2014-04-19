App.BoxesNewRoute = Em.Route.extend
  activate: ->
    App.get('currentUser').fetchN2O()
    App.get('snapshots').reload()

  setupController: (controller, model) ->
    @_super.apply this, arguments
    controller.set 'isIntro', false
    controller.newRecord()

  deactivate: ->
    @controller.set 'content', null
