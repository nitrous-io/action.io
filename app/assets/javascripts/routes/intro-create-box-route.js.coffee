App.IntroCreateBoxRoute = Em.Route.extend
  activate: ->
    App.get('currentUser').fetchN2O()

  setupController: ->
    @_super.apply this, arguments
    controller = @controllerFor 'boxesNew'
    controller.set 'isIntro', true
    controller.newRecord()

  renderTemplate: ->
    @render 'intro/create_box', controller: 'boxesNew'

  deactivate: ->
    @controllerFor('boxesNew').setProperties(isIntro: false, content: null)
