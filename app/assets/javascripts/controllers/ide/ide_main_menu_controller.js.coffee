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

  navigateActivateConsole: ->
    if document = AIO.get 'router.ideEditorController.activeTab'
      document.set 'focused', false
    if consoleSession = AIO.get 'router.ideConsoleController.activeTab'
      consoleSession.set 'focused', true

  shouldCycleTab: (->
    (AIO.get 'router.ideEditorController.tabCount') > 1
  ).property('AIO.router.ideEditorController.tabCount')

  cycleNextActiveTab: ->
    if @get 'shouldCycleTab'
      ideEditorController = AIO.get 'router.ideEditorController'
      ideEditorController.makeNextTabActive()

  cyclePrevActiveTab: ->
    if @get 'shouldCycleTab'
      ideEditorController = AIO.get 'router.ideEditorController'
      ideEditorController.makePrevTabActive()
