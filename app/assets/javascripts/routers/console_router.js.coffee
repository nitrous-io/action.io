class aio.routers.ConsoleRouter extends Backbone.Router
  initialize: (options) ->
    aio.app.boxes = new aio.collections.Boxes
    aio.app.boxes.reset(options.boxes)
    aio.app.boxTemplates = new aio.collections.BoxTemplates
    aio.app.boxTemplates.reset(options.boxTemplates)
    aio.app.regions = options.regions
    @layoutView = new aio.views.console.LayoutView
    @loadingIndicatorView = aio.app.loadingIndicatorView = new aio.views.LoadingIndicatorView
    $('#page_content').empty().append(@layoutView.render().$el)
    $('#page_content').append(@loadingIndicatorView.render().$el)

  routes:
    'boxes/new' : 'boxes_new'
    'boxes/:id' : 'boxes_show'

  boxes_new: ->
    view = new aio.views.console.boxes.NewView
    @layoutView.showContentView(view)

  boxes_show: (id) ->
    box = aio.app.boxes.get(id)
    if box
      view = new aio.views.console.boxes.ShowView(model: aio.app.boxes.get(id))
      @layoutView.showContentView(view)
    else
      window.redirectTo('#')

