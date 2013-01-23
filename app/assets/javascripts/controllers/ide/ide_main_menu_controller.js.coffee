AIO.IdeMainMenuController = Em.Controller.extend
  initialize: ->
  reset: ->

  fileNew: ->
    if editorController = AIO.get 'router.ideEditorController'
      editorController.createTab()

  fileSave: ->
    if editorController = AIO.get 'router.ideEditorController'
      editorController.saveDocument editorController.get('activeTab')

  fileClose: ->
    if editorController = AIO.get 'router.ideEditorController'
      editorController.removeTab()

  fileRefreshTree: ->
    if sidebarController = AIO.get 'router.ideSidebarController'
      sidebarController.refreshAll()

  viewFocusConsole: ->
    if document = AIO.get 'router.ideEditorController.activeTab'
      document.set 'focused', false
    if consoleSession = AIO.get 'router.ideConsoleController.activeTab'
      consoleSession.set 'focused', true

    AIO.util.mixpanelIncrement 'IDE Focused Console'

  viewSelectNextTab: ->
    if editorController = AIO.get 'router.ideEditorController'
      editorController.makeNextTabActive()

  viewSelectPreviousTab: ->
    if editorController = AIO.get 'router.ideEditorController'
      editorController.makePreviousTabActive()

  viewToggleFullScreenConsole: ->
    if consoleController = AIO.get 'router.ideConsoleController'
      consoleController.toggleProperty 'fullscreen'
      AIO.util.mixpanelIncrement 'IDE Toggled Console Fullscreen'
    this.viewFocusConsole()

