activeDocumentSet = (attr, val) ->
  if tab = AIO.get 'router.ideEditorController.activeTab'
    tab.set attr, val

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

  editFind: ->
    activeDocumentSet 'findTrigger', true

  editFindNext: ->
    activeDocumentSet 'findNextTrigger', true

  editFindPrevious: ->
    activeDocumentSet 'findPrevTrigger', true

  editReplace: ->
    activeDocumentSet 'replaceTrigger', true

  editReplaceAll: ->
    activeDocumentSet 'replaceAllTrigger', true

  viewFocusConsole: ->
    if document = AIO.get 'router.ideEditorController.activeTab'
      document.set 'focused', false
    if consoleSession = AIO.get 'router.ideConsoleController.activeTab'
      consoleSession.set 'focused', true

    AIO.util.mixpanelIncrement 'ide_focused_console_count'

  viewFocusEditor: ->
    if document = AIO.get 'router.ideEditorController.activeTab'
      document.set 'focused', true
    if consoleSession = AIO.get 'router.ideConsoleController.activeTab'
      consoleSession.set 'focused', false

  viewSelectNextTab: ->
    if editorController = AIO.get 'router.ideEditorController'
      editorController.makeNextTabActive()

  viewSelectPreviousTab: ->
    if editorController = AIO.get 'router.ideEditorController'
      editorController.makePreviousTabActive()

  viewToggleFullScreenConsole: ->
    if consoleController = AIO.get 'router.ideConsoleController'
      consoleController.toggleProperty 'fullscreen'
      AIO.util.mixpanelIncrement 'ide_toggled_console_fullscreen_count'
    this.viewFocusConsole()

  viewToggleFullScreenEditor: ->
    if editorController = AIO.get 'router.ideEditorController'
      editorController.toggleProperty 'fullscreen'
    this.viewFocusEditor()

  collaborateManageCollaborators: ->
    if collaborationPaneController = AIO.get 'router.ideCollaborationPaneController'
      collaborationPaneController.showManageCollaboratorsDialog()

  collaborateToggleChat: ->
    if layoutController = AIO.get 'router.ideLayoutController'
      layoutController.toggleProperty 'collaborationPaneHidden'

  manageAutoparts: ->
    if autopartsController = AIO.get 'router.ideAutopartsController'
      autopartsController.showManageDialog()

  manageBasicAuth: ->
    if basicAuthController = AIO.get 'router.ideBasicAuthController'
      basicAuthController.showAuthDialog()

  manageCustomDomain: ->
    if customDomainController = AIO.get 'router.ideCustomDomainController'
      customDomainController.showCustomDomainDialog()
