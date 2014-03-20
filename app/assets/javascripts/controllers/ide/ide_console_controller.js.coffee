AIO.IdeConsoleController = Em.ArrayController.extend AIO.IdeTabControllerMixin, Em.Evented,
  modelClass: AIO.ConsoleSession
  content: null
  fullscreen: false
  sessions: null

  initialize: ->
    @set 'content', []
    @set 'sessions', [] # keep tracks of which sessions we are connecting to
    @set 'fullscreen', (AIO.localStorage.get('fullscreenConsole') ? false)

  fullscreenDidChange: (->
    AIO.localStorage.set 'fullscreenConsole', @get('fullscreen')
  ).observes 'fullscreen'

  createTab: (attrs={}) ->
    id = @generateId()
    @createTabWithId(attrs, id)

  createTabWithId: (attrs={}, id) ->
    # if we havent connected to it, open a new session
    unless _.contains(@get('sessions'), id)
      AIO.util.mixpanelIncrement 'ide_new_console_tab_count'
      @get('sessions').push id
      @_super(attrs, id)

  reset: ->
    @set 'content', null
