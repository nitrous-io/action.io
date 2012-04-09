aio.routers ||= {}

class aio.routers.ConsoleRouter extends Backbone.Router
  initialize: ->
    aio.app.collections.boxes = new aio.collections.Boxes
    aio.app.collections.boxTemplates = new aio.collections.BoxTemplates
    @indexView = new aio.views.console.IndexView
    $('#page_content').empty().append(@indexView.render().$el)
    this.fetchBoxes()
    this.fetchBoxTemplates()

  routes:
    'new_box' : 'newBox'

  newBox: ->
    @indexView.showNewBoxView()

  fetchBoxes: ->
    @indexView.loadingIndicatorView.show()
    aio.app.collections.boxes.fetch success: =>
      @indexView.loadingIndicatorView.hide()

  fetchBoxTemplates: ->
    @indexView.loadingIndicatorView.show()
    aio.app.collections.boxTemplates.fetch success: =>
      @indexView.loadingIndicatorView.hide()
      @indexView.sidebarView.$newBoxButton.removeAttr('disabled')


