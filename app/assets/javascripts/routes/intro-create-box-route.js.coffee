App.IntroCreateBoxRoute = Em.Route.extend
  controllerName: 'boxesNew'

  activate: ->
    App.get('currentUser').fetchN2O()

  setupController: (controller, model) ->
    @_super.apply this, arguments
    controller.set 'isIntro', true
    controller.newRecord()

  renderTemplate: ->
    @render 'intro/create_box', controller: 'boxesNew'

  deactivate: ->
    @controllerFor('boxesNew').setProperties(isIntro: false, content: null)
