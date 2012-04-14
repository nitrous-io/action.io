class aio.routers.ConsoleRouter extends Backbone.Router
  initialize: (options) ->
    aio.app.boxes = new aio.collections.Boxes
    aio.app.boxTemplates = new aio.collections.BoxTemplates
    aio.app.publicKeys = new aio.collections.PublicKeys
    aio.app.boxes.reset(options.boxes)
    aio.app.boxTemplates.reset(options.boxTemplates)
    aio.app.publicKeys.reset(options.publicKeys)
    aio.app.regions = options.regions
    @layoutView = new aio.views.console.LayoutView
    @loadingIndicatorView = aio.app.loadingIndicatorView = new aio.views.LoadingIndicatorView
    $('#page_content').empty().append(@layoutView.render().$el)
    $('#page_content').append(@loadingIndicatorView.render().$el)

  routes:
    'boxes/new'            : 'boxes#new'
    'boxes/:id'            : 'boxes#show'
    'public_keys'          : 'public_keys#index'
    'public_keys/new'      : 'public_keys#new'
    'public_keys/:id/edit' : 'public_keys#edit'

  'boxes#new': ->
    view = new aio.views.console.boxes.NewView(collection: aio.app.boxes)
    @layoutView.showContentView(view)

  'boxes#show': (id) ->
    box = aio.app.boxes.get(id)
    if box
      view = new aio.views.console.boxes.ShowView(model: box)
      @layoutView.showContentView(view)
    else
      window.redirectTo('#')

  'public_keys#index': ->
    view = new aio.views.console.public_keys.IndexView(collection: aio.app.publicKeys)
    @layoutView.showContentView(view)

  'public_keys#new': ->
    view = new aio.views.console.public_keys.NewView(collection: aio.app.publicKeys)
    @layoutView.showContentView(view)

  'public_keys#edit': (id) ->
    publicKey = aio.app.publicKeys.get(id)
    if publicKey
      view = new aio.views.console.public_keys.EditView(model: publicKey)
      @layoutView.showContentView(view)
    else
      window.redirectTo('#')

