AIO.IdeConsoleController = Em.ArrayController.extend AIO.IdeTabControllerMixin,
  modelClass: AIO.ConsoleSession
  content: null
  fullscreen: false

  sessionId: null

  tmuxSocketBinding: Em.Binding.oneWay 'AIO.router.ideController.tmuxSocket'

  createSession: (->
    return unless @get 'tmuxSocket.startedFirstTime'

    socket = @get 'tmuxSocket'
    # create a new tmux session
    # FIXME: this need not to have a timeout
    window.setTimeout(=>
      socket.createSession (err, sessionId) =>
        unless err
          @set 'sessionId', sessionId
    , 1000)
  ).observes 'tmuxSocket.startedFirstTime'

  initialize: ->
    @set 'content', []
    @set 'fullscreen', (AIO.localStorage.get('fullscreenConsole') ? false)

  fullscreenDidChange: (->
    AIO.localStorage.set 'fullscreenConsole', @get('fullscreen')
  ).observes 'fullscreen'

  reset: ->
    @set 'content', null

  createTab: (attrs={}) ->
    AIO.util.mixpanelIncrement 'ide_new_console_tab_count'
    lastTabId = @get('content.lastObject')?.get('tabId') ? -1

    # send command to tmux to create window
    # check if a tmux session exist
    if sessionId = @get 'sessionId'
      socket = @get 'tmuxSocket'
      windowId = lastTabId + 1
      socket.createWindow windowId

    attrs.tabId = lastTabId + 1
    @_super attrs

  removeTab: (tab) ->
    socket = @get 'tmuxSocket'

    # check if a tmux session exist
    if sessionId = @get 'sessionId'
      socket.removeWindow tab.get('tabId')

    @_super tab

  makeTabActive: (tab) ->
    socket = @get 'tmuxSocket'

    # check if a tmux session exist
    if sessionId = @get 'sessionId'
      socket.selectWindow tab.get('tabId')

    @_super tab
