class aio.routers.EditorRouter extends Backbone.Router
  initialize: (options) ->
    aio.app.box = new aio.models.Box(options.box) if options.box
    @layoutView = new aio.views.editor.LayoutView
    $('#page_content').empty().append(@layoutView.render().$el)
    @layoutView.didAddToDOM()

