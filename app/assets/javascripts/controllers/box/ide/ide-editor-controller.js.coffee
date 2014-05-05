App.IdeEditorController = Em.ArrayController.extend App.IdeTabControllerMixin,
  modelClass: App.Document
  content: null
  saveDialog: null
  confirmCloseDialog: null
  fullscreen: false
  chatNotification: null

  sftpSocketBinding: Em.Binding.oneWay 'App.router.boxIdeController.sftpSocket'
  sftpSocketReadyBinding: Em.Binding.oneWay 'App.router.boxIdeController.sftpSocketReady'

  softTabs: true
  tabSize: 2
  theme: 'vibrant-ink'
  wrapLines: true
  highlightLine: true
  showLineNumbers: true
  rulerColumn: null
  showTrailingSpace: false
  matchBrackets: true
  autoCloseBrackets: true

  initialize: ->
    @set 'content', []
    @set 'fullscreen', false

    if boxId = App.get 'router.boxIdeController.content.id'
      if editorSettings = App.localStorage.get("box:#{boxId}:editorSettings") ||
                          App.localStorage.delete("box:#{boxId}:lastTabSettings") # for backward compatibility
        @set 'softTabs', editorSettings.softTabs
        @set 'tabSize', editorSettings.tabSize
        @set 'theme', editorSettings.theme if editorSettings.theme
        @set 'wrapLines', editorSettings.wrapLines if editorSettings.wrapLines?
        @set 'highlightLine', editorSettings.highlightLine if editorSettings.highlightLine?
        @set 'showLineNumbers', editorSettings.showLineNumbers if editorSettings.showLineNumbers?
        @set 'rulerColumn', editorSettings.rulerColumn if editorSettings.rulerColumn?
        @set 'showTrailingSpace', editorSettings.showTrailingSpace if editorSettings.showTrailingSpace?
        @set 'matchBrackets', editorSettings.matchBrackets if editorSettings.matchBrackets?
        @set 'autoCloseBrackets', editorSettings.autoCloseBrackets if editorSettings.autoCloseBrackets?

  reset: ->
    @set 'content', null
    @set 'saveDialog', null
    @set 'confirmCloseDialog', null
    @set 'fullscreen', false

  editorSettingsChanged: (->
    if boxId = App.get 'router.boxIdeController.content.id'
      App.localStorage.set "box:#{boxId}:editorSettings",
        softTabs: @get('softTabs')
        tabSize: @get('tabSize')
        theme: @get('theme')
        wrapLines: @get('wrapLines')
        highlightLine: @get('highlightLine')
        showLineNumbers: @get('showLineNumbers')
        rulerColumn: @get('rulerColumn')
        showTrailingSpace: @get('showTrailingSpace')
        matchBrackets: @get('matchBrackets')
        autoCloseBrackets: @get('autoCloseBrackets')
  ).observes 'softTabs', 'tabSize', 'theme', 'wrapLines', 'highlightLine', 'showTrailingSpace', 'showLineNumbers', 'rulerColumn', 'matchBrackets', 'autoCloseBrackets'

  createTab: (attrs={}) ->
    App.util.mixpanel 'IDE New Document Tab'
    App.util.mixpanelIncrement 'ide_new_document_tab_count'
    @_super(attrs)
    this._notifyFileOpened()

  removeTab: (tab, forceRemove = false) ->
    tab = @get 'activeTab' unless tab
    if tab.get('clean') || forceRemove
      @_super(tab)
    else
      @set 'confirmCloseDialog', App.ConfirmCloseDialog.create document: tab

  saveDocument: (document) ->
    return unless @get 'sftpSocketReady'
    return if document.get('isImageFile')

    if path = document.get 'path'
      if sftpSocket = @get 'sftpSocket'
        path.incrementProperty 'loadCount'
        sftpSocket.writeFile path.get('absolutePath'), document.get('content'), (err, absolutePath) ->
          path.decrementProperty 'loadCount'
          document.set 'clean', true
          App.util.mixpanel 'IDE Document Saved'
          App.util.mixpanelIncrement 'ide_document_saved_count'
    else
      @set 'saveDialog', App.SaveDialog.create document: document

  saveNewDocument: ->
    return unless @get 'sftpSocketReady'
    saveDialog = @get 'saveDialog'
    unless saveDialog.validate()
      saveDialog.set 'saving', true
      documentContent = saveDialog.get 'document.content'
      path = saveDialog.get 'path'
      if sftpSocket = @get 'sftpSocket'
        sftpSocket.writeNewFile path, documentContent, _.bind(@didWriteNewFileContent, this)

  didWriteNewFileContent: (err, absolutePath) ->
    saveDialog = @get 'saveDialog'
    if err
      errors = {}
      if err.indexOf('aio:file_exists') != -1
        errors.path = ['A file already exists in the path.']
      else
        errors.base = [err]
      saveDialog.set 'errors', errors
    else
      path = App.Path.create absolutePath: absolutePath
      saveDialog.set 'document.path', path
      saveDialog.set 'document.clean', true
      saveDialog.set 'document.focused', true
      sidebarController = App.get 'router.ideSidebarController'
      sidebarController.refreshPath path.get('parentAbsolutePath')
      @set 'saveDialog', null
      App.util.mixpanel 'IDE New Document Saved'
      App.util.mixpanelIncrement 'ide_new_document_saved_count'
    saveDialog.set 'saving', false

  _notifyFileOpened: ->
    tab = @get 'activeTab'
    collaborationPaneController = App.get 'router.ideCollaborationPaneController'
    if tab && collaborationPaneController
      if absolutePath = tab.get 'path.absolutePath'
        collaborationPaneController.sendMessage absolutePath, App.CollabMessage.TypeFileOpen
