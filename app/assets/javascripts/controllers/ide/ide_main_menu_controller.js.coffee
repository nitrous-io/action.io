AIO.IdeMainMenuController = Em.Controller.extend
  needs: ['ide', 'ideLayout', 'ideMainMenu', 'ideSidebar', 'ideEditor', 'ideConsole', 'ideCollaborators']
  initialize: ->
  reset: ->

  fileNew: ->
    if editorController = @get 'controllers.ideEditor'
      editorController.createTab()

  fileSave: ->
    if editorController = @get 'controllers.ideEditor'
      editorController.saveDocument editorController.get('activeTab')

  fileClose: ->
    if editorController = @get 'controllers.ideEditor'
      editorController.removeTab()

  fileRefreshTree: ->
    if sidebarController = @get 'controllers.ideSidebar'
      sidebarController.refreshAll()

  viewFocusConsole: ->
    if document = @get 'controllers.ideEditor.activeTab'
      document.set 'focused', false
    if consoleSession = @get 'controllers.ideConsole.activeTab'
      consoleSession.set 'focused', true

    AIO.util.mixpanelIncrement 'ide_focused_console_count'

  viewSelectNextTab: ->
    if editorController = @get 'controllers.ideEditor'
      editorController.makeNextTabActive()

  viewSelectPreviousTab: ->
    if editorController = @get 'controllers.ideEditor'
      editorController.makePreviousTabActive()

  viewToggleFullScreenConsole: ->
    if consoleController = @get 'controllers.ideConsole'
      consoleController.toggleProperty 'fullscreen'
      AIO.util.mixpanelIncrement 'ide_toggled_console_fullscreen_count'
    this.viewFocusConsole()

  collaborateManageCollaborators: ->
    if collaboratorsController = @get 'controllers.ideCollaborators'
      collaboratorsController.showManageCollaboratorsDialog()
