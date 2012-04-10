aio.routers ||= {}

class aio.routers.ConsoleRouter extends Backbone.Router
  initialize: (options) ->
    aio.app.boxes = new aio.collections.Boxes
    aio.app.boxes.reset(options.boxes)
    aio.app.boxTemplates = new aio.collections.BoxTemplates
    aio.app.boxTemplates.reset(options.boxTemplates)
    @indexView = new aio.views.console.IndexView
    @loadingIndicatorView = aio.app.loadingIndicatorView = new aio.views.LoadingIndicatorView
    $('#page_content').empty().append(@indexView.render().$el)
    $('#page_content').append(@loadingIndicatorView.render().$el)

  routes:
    'new_box' : 'newBox'

  newBox: ->
    @indexView.showNewBoxView()

