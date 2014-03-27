AIO.IdeConsoleController = Em.ArrayController.extend AIO.IdeTabControllerMixin, Em.Evented,
  modelClass: AIO.ConsoleSession
  content: null
  fullscreen: false
  muxSocketBinding: Em.Binding.oneWay 'AIO.router.ideController.muxSocket'

  initialize: ->
    @set 'content', []
    @set 'fullscreen', (AIO.localStorage.get('fullscreenConsole') ? false)

  fullscreenDidChange: (->
    AIO.localStorage.set 'fullscreenConsole', @get('fullscreen')
  ).observes 'fullscreen'

  createTab: (attrs={}) ->
    id = @generateId()
    @createTabWithId(attrs, id)

  createTabWithId: (attrs={}, id) ->
    if existingSession = @findById(id)
      return existingSession
    # if we havent connected to it, open a new session
    AIO.util.mixpanelIncrement 'ide_new_console_tab_count'
    @_super(attrs, id)

  # sync existing sessions of the box
  syncSessions: () ->
    muxSocket = @get 'muxSocket'
    return unless muxSocket
    content = @get('content')
    muxSocket.listAll (err, serverSessions) =>
      return if err
      for data in serverSessions
        return existingSession if existingSession = @findById(data.id)
        tab = @get('modelClass').create data
        content.pushObject tab

  reset: ->
    @set 'content', null
