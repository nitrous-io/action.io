AIO.IdeLayoutController = Em.Controller.extend
  mainMenuViewHeight: 0
  consoleHeight: 180
  sidebarWidth: 240
  collaborationPaneWidth: 240
  collaborationPaneHidden: true

  initialize: ->
    @set 'collaborationPaneHidden', (AIO.localStorage.get('collaborationPaneHidden') ? true)

  reset: ->

  _collaborationPaneHiddenDidChange: (->
    AIO.localStorage.set 'collaborationPaneHidden', @get('collaborationPaneHidden')
  ).observes 'collaborationPaneHidden'
