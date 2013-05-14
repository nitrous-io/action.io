AIO.IdeEditorController = Em.ArrayController.extend AIO.IdeTabControllerMixin,
  modelClass: AIO.Document
  content: null
  saveDialog: null
  confirmCloseDialog: null
  fullscreen: false

  sftpSocketBinding: Em.Binding.oneWay 'AIO.router.ideController.sftpSocket'
  sftpSocketReadyBinding: Em.Binding.oneWay 'sftpSocket.started'

  softTabs: true
  tabSize: 2

  initialize: ->
    @set 'content', []
    @set 'fullscreen', false

    if boxId = AIO.get 'router.ideController.content.id'
      if lastTabSettings = AIO.localStorage.get("box:#{boxId}:lastTabSettings")
        @set 'softTabs', lastTabSettings.softTabs
        @set 'tabSize', lastTabSettings.tabSize

  reset: ->
    @set 'content', null
    @set 'saveDialog', null
    @set 'confirmCloseDialog', null
    @set 'fullscreen', false

  tabSettingsChanged: (->
    if boxId = AIO.get 'router.ideController.content.id'
      AIO.localStorage.set "box:#{boxId}:lastTabSettings", { softTabs: @get('softTabs'), tabSize: @get('tabSize') }
  ).observes 'softTabs', 'tabSize'

  createTab: (attrs={}) ->
    AIO.util.mixpanel 'IDE New Document Tab'
    AIO.util.mixpanelIncrement 'ide_new_document_tab_count'
    @_super(attrs)
    this._notifyFileOpened()

  removeTab: (tab, forceRemove = false) ->
    tab = @get 'activeTab' unless tab
    if tab.get('clean') || forceRemove
      @_super(tab)
    else
      @set 'confirmCloseDialog', AIO.ConfirmCloseDialog.create document: tab

  saveDocument: (document) ->
    return unless @get 'sftpSocketReady'
    if path = document.get 'path'
      AIO.util.mixpanel 'IDE Document Saved'
      AIO.util.mixpanelIncrement 'ide_document_saved_count'
      if sftpSocket = @get 'sftpSocket'
        path.incrementProperty 'loadCount'
        sftpSocket.writeFile path.get('absolutePath'), document.get('content'), (err, absolutePath) ->
          path.decrementProperty 'loadCount'
          document.set 'clean', true
    else
      @set 'saveDialog', AIO.SaveDialog.create document: document

  saveNewDocument: ->
    return unless @get 'sftpSocketReady'
    saveDialog = @get 'saveDialog'
    unless saveDialog.validate()
      AIO.util.mixpanel 'IDE New Document Saved'
      AIO.util.mixpanelIncrement 'ide_new_document_saved_count'
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
      path = AIO.Path.create absolutePath: absolutePath
      saveDialog.set 'document.path', path
      saveDialog.set 'document.clean', true
      saveDialog.set 'document.focused', true
      sidebarController = AIO.get 'router.ideSidebarController'
      sidebarController.refreshPath path.get('parentAbsolutePath')
      @set 'saveDialog', null
    saveDialog.set 'saving', false

  _notifyFileOpened: ->
    tab = @get 'activeTab'
    collaborationPaneController = AIO.get 'router.ideCollaborationPaneController'
    if tab && collaborationPaneController
      if absolutePath = tab.get 'path.absolutePath'
        collaborationPaneController.sendMessage absolutePath, AIO.CollabMessage.fileOpen
