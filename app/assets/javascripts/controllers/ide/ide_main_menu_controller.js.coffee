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

  navigateFocusConsole: ->
    if document = AIO.get 'router.ideEditorController.activeTab'
      document.set 'focused', false
    if consoleSession = AIO.get 'router.ideConsoleController.activeTab'
      consoleSession.set 'focused', true

  navigateSelectNextTab: ->
    if editorController = AIO.get 'router.ideEditorController'
      editorController.makeNextTabActive()

  navigateSelectPreviousTab: ->
    if editorController = AIO.get 'router.ideEditorController'
      editorController.makePreviousTabActive()

