class aio.routers.ConsoleRouter extends Backbone.Router
  initialize: (options) ->
    aio.app.boxes        = new aio.collections.Boxes
    aio.app.boxTemplates = new aio.collections.BoxTemplates
    aio.app.publicKeys   = new aio.collections.PublicKeys
    aio.app.regions      = new aio.collections.Regions
    aio.app.userId       = options.userId

    aio.app.boxes.reset        options.boxes
    aio.app.boxTemplates.reset options.boxTemplates
    aio.app.publicKeys.reset   options.publicKeys
    aio.app.regions.reset      options.regions

    @layoutView = new aio.views.console.LayoutView
    $('#page_content').empty().append(@layoutView.render().$el)

    @loadingIndicatorView = aio.app.loadingIndicatorView = new aio.views.LoadingIndicatorView
    $('#page_content').append(@loadingIndicatorView.render().$el)

    @channel = aio.app.pusher.subscribe "private-user-#{aio.app.userId}"
    @channel.bind 'aio:box_updated', (data) ->
      box = aio.app.boxes.get(data.id)
      box.set(data) if box

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

