aio.routers ||= {}

class aio.routers.ConsoleRouter extends Backbone.Router
  initialize: ->
    aio.app.boxes = new aio.collections.Boxes
    aio.app.boxTemplates = new aio.collections.BoxTemplates
    @indexView = new aio.views.console.IndexView
    @loadingIndicatorView = aio.app.loadingIndicatorView = new aio.views.LoadingIndicatorView
    $('#page_content').empty().append(@indexView.render().$el)
    $('#page_content').append(@loadingIndicatorView.render().$el)
    this.fetchBoxes()
    this.fetchBoxTemplates()

  routes:
    'new_box' : 'newBox'

  newBox: ->
    @indexView.showNewBoxView()

  fetchBoxes: ->
    @loadingIndicatorView.show()
    aio.app.boxes.fetch success: =>
      @loadingIndicatorView.hide()

  fetchBoxTemplates: ->
    @loadingIndicatorView.show()
    aio.app.boxTemplates.fetch success: =>
      @loadingIndicatorView.hide()
      @indexView.sidebarView.$newBoxButton.removeAttr('disabled')


