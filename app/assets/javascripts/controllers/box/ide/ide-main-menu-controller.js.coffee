activeDocumentSet = (attr, val) ->
  if tab = App.get 'router.ideEditorController.activeTab'
    tab.set attr, val

App.IdeMainMenuController = Em.Controller.extend
  needs: ['ideEditor']
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
    if sidebarController = App.get 'router.ideSidebarController'
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

  editFoldCode: ->
    activeDocumentSet 'foldCodeTrigger', true

  editUnfoldCode: ->
    activeDocumentSet 'unfoldCodeTrigger', true

  viewFocusConsole: ->
    if document = App.get 'router.ideEditorController.activeTab'
      document.set 'focused', false
    if consoleSession = App.get 'router.ideConsoleController.activeTab'
      consoleSession.set 'focused', true

    App.util.mixpanelIncrement 'ide_focused_console_count'

  viewFocusEditor: ->
    if document = App.get 'router.ideEditorController.activeTab'
      document.set 'focused', true
    if consoleSession = App.get 'router.ideConsoleController.activeTab'
      consoleSession.set 'focused', false

  viewSelectNextTab: ->
    if editorController = @get 'controllers.ideEditor'
      editorController.makeNextTabActive()

  viewSelectPreviousTab: ->
    if editorController = @get 'controllers.ideEditor'
      editorController.makePreviousTabActive()

  viewToggleFullScreenConsole: ->
    if consoleController = App.get 'router.ideConsoleController'
      consoleController.toggleProperty 'fullscreen'
      App.util.mixpanelIncrement 'ide_toggled_console_fullscreen_count'
    this.viewFocusConsole()

  viewToggleFullScreenEditor: ->
    @_toggleEditorProperty 'fullscreen'
    this.viewFocusEditor()

  collaborateManageCollaborators: ->
    if collaborationPaneController = App.get 'router.ideCollaborationPaneController'
      collaborationPaneController.showManageCollaboratorsDialog()

  collaborateToggleChat: ->
    if layoutController = App.get 'router.ideLayoutController'
      layoutController.toggleProperty 'collaborationPaneHidden'

  manageAutoparts: ->
    if autopartsController = App.get 'router.ideAutopartsController'
      autopartsController.showManageDialog()

  manageBasicAuth: ->
    if basicAuthController = App.get 'router.ideBasicAuthController'
      basicAuthController.showAuthDialog()

  viewSelectTheme: (theme) ->
    if editorController = @get 'controllers.ideEditor'
      editorController.set 'theme', theme

  viewToggleLineNumbers: ->
    @_toggleEditorProperty 'showLineNumbers'

  viewSetRulerColumn: (column) ->
    if editorController = @get 'controllers.ideEditor'
      editorController.set 'rulerColumn', column

  viewToggleTrailingSpace: ->
    @_toggleEditorProperty 'showTrailingSpace'

  viewToggleWrapLines: ->
    @_toggleEditorProperty 'wrapLines'

  viewToggleHighlightLine: ->
    @_toggleEditorProperty 'highlightLine'

  viewToggleMatchBrackets: ->
    @_toggleEditorProperty 'matchBrackets'

  viewToggleAutoCloseBrackets: ->
    @_toggleEditorProperty 'autoCloseBrackets'

  _toggleEditorProperty: (property) ->
    if editorController = @get 'controllers.ideEditor'
      editorController.toggleProperty(property)
