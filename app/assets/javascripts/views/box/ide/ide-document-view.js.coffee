TAB_SIZES = [2, 3, 4, 8]

App.IdeDocumentView = Em.View.extend
  templateName: 'templates/box/ide/document'
  classNames: ['ide_document_view']

  document: null
  codeMirror: null
  firepad: null
  firebase: null
  collabMode: false
  firepadEnabling: false

  mode: 'text/plain'
  softTabsBinding: 'controller.softTabs'
  tabSizeBinding: 'controller.tabSize'
  themeBinding: 'controller.theme'
  showLineNumbersBinding: 'controller.showLineNumbers'

  init: ->
    this.documentPathDidChange()
    @_super.apply this, arguments

  didInsertElement: ->
    @_super()
    this.insertCodeMirror()

  willDestroyElement: ->
    @_super()
    @set 'collabMode', false
    this.destroyCodeMirror()

  modeName: (->
    CodeMirror.MODES[@get('mode')]
  ).property 'mode'

  collabModeDisabled: (->
    return false if @get('collabMode')
    !@get('document.path.absolutePath') || !@get('document.clean') || @get('firepadEnabling')
  ).property 'collabMode', 'document.path.absolutePath', 'document.clean', 'firepadEnabling'

  availableModes: (->
    mode = @get 'mode'
    _.map CodeMirror.MODES_ARRAY, (m) ->
      { name: m.name, mode: m.mode, active: m.mode == mode }
  ).property 'mode'

  availableTabSizes: (->
    tabSize = @get 'tabSize'
    _.map TAB_SIZES, (size) ->
      { size: size, active: size == tabSize }
  ).property 'tabSize'

  saving: (->
    if loadCount = @get 'document.path.loadCount'
      loadCount > 0
  ).property 'document.path.loadCount'

  savingDisabled: (->
    @get('saving') || App.get('offline')
  ).property 'saving', 'App.offline'

  triggerFind: (->
    if @get 'document.findTrigger'
      CodeMirror.commands.find @get('codeMirror')
      @set 'document.findTrigger', false
  ).observes 'document.findTrigger'

  triggerFindNext: (->
    if @get 'document.findNextTrigger'
      CodeMirror.commands.findNext @get('codeMirror')
      @set 'document.findNextTrigger', false
  ).observes 'document.findNextTrigger'

  triggerFindPrev: (->
    if @get 'document.findPrevTrigger'
      CodeMirror.commands.findPrev @get('codeMirror')
      @set 'document.findPrevTrigger', false
  ).observes 'document.findPrevTrigger'

  triggerReplace: (->
    if @get 'document.replaceTrigger'
      CodeMirror.commands.replace @get('codeMirror')
      @set 'document.replaceTrigger', false
  ).observes 'document.replaceTrigger'

  triggerRelaceAll: (->
    if @get 'document.replaceAllTrigger'
      CodeMirror.commands.replaceAll @get('codeMirror')
      @set 'document.replaceAllTrigger', false
  ).observes 'document.replaceAllTrigger'

  closeDocument: (->
    if @get 'document.path.deleted'
      this.remove()
  ).observes 'document.path.deleted'

  insertCodeMirror: ->
    $codeEditor = @$('.code_editor')
    if $codeEditor.length > 0
      cm = CodeMirror $codeEditor[0],
        theme          : @get 'theme'
        mode           : @get 'mode'
        tabSize        : @get 'tabSize'
        indentUnit     : @get 'tabSize'
        indentWithTabs : !@get 'softTabs'
        lineNumbers    : @get 'showLineNumbers'
        value          : @get 'document.content'
        styleSelectedText: true # Selected text gets '.CodeMirror-selectedtext' class.
        highlightSelectionMatches: true
        extraKeys:
          # If there is a selection, pressing Tab will indent it, otherwise,
          # just insert a tab character or spaces.
          'Tab': (cm) =>
            if cm.getSelection().length
              CodeMirror.commands.indentMore cm
            else
              if @get 'softTabs'
                spaces = Array(cm.getOption("indentUnit") + 1).join(" ")
                cm.replaceSelection spaces, "end", "+input"
              else
                CodeMirror.commands.insertTab cm

      macExtraKeys =
        'Cmd-/': 'toggleComment'
      pcExtraKeys =
        'Ctrl-/': 'toggleComment'
      if App.util.IsMac
        cm.addKeyMap(macExtraKeys)
      else
        cm.addKeyMap(pcExtraKeys)

      cm.on 'gutterClick', (cm, line) ->
        cm.setSelection(CodeMirror.Pos(line, 0), CodeMirror.Pos(line + 1, 0))

      cm.on "change", (cm, data) =>
        unless @isDestroyed
          if @get('document.content') != (content = cm.getValue())
            @set 'document.content', content
          if @get('document.clean') != (clean = cm.isClean())
            @set 'document.clean', clean

      cm.on "focus", =>
        if !@get 'document.focused'
          @set 'document.focused', true

      cm.on "blur", =>
        if @get 'document.focused'
          @set 'document.focused', false

      @set 'codeMirror', cm

  destroyCodeMirror: ->
    if cm = @get 'codeMirror'
      cm.off 'change'
      cm.off 'focus'
      cm.off 'blur'
    @set 'codeMirror', null

  modeDidChange: (->
    if cm = @get 'codeMirror'
      cm.setOption 'mode', @get 'mode'
  ).observes 'mode'

  tabSizeDidChange: (->
    if cm = @get 'codeMirror'
      tabSize = @get 'tabSize'
      cm.setOption 'tabSize', tabSize
      cm.setOption 'indentUnit', tabSize
  ).observes 'tabSize'

  softTabsDidChange: (->
    if cm = @get 'codeMirror'
      cm.setOption 'indentWithTabs', !@get 'softTabs'
  ).observes 'softTabs'

  themeDidChange: (->
    if cm = @get 'codeMirror'
      cm.setOption 'theme', @get('theme')
  ).observes 'theme'

  showLineNumbersDidChange: (->
    if cm = @get 'codeMirror'
      cm.setOption 'lineNumbers', @get('showLineNumbers')
  ).observes 'showLineNumbers'

  contentDidChange: (->
    if cm = @get 'codeMirror'
      if cm.getValue() != (content = @get 'document.content')
        cm.setValue content
  ).observes 'document.content'

  cleanDidChange: (->
    if cm = @get 'codeMirror'
      documentIsClean = @get('document.clean')

      if cm.isClean() != documentIsClean
        cm.markClean()
      if documentIsClean && @get('collabMode')
        this._setCollabSavedState()
  ).observes 'document.clean'

  consoleHeightDidChange: (->
    if cm = @get 'codeMirror'
      cm.refresh()
  ).observes 'App.router.ideLayoutController.consoleHeight'

  editorWidthDidChange: (->
    if cm = @get 'codeMirror'
      cm.refresh()
  ).observes(
    'App.router.ideLayoutController.sidebarWidth',
    'App.router.ideLayoutController.collaborationPaneWidth',
    'App.router.ideLayoutController.collaborationPaneHidden'
  )

  editorFullscreenToggled: (->
    if cm = @get 'codeMirror'
      cm.refresh()
  ).observes 'App.router.ideEditorController.fullscreen'

  focusedDidChange: (->
    if cm = @get 'codeMirror'
      if focused = @get 'document.focused'
        cm.refresh()
        cm.focus()
      #else
        #@$('textarea')[0].blur()
  ).observes 'document.focused'

  documentPathDidChange: (->
    if fileName = @get 'document.path.name'
      @set 'mode', App.FileTypeDetect.detect fileName
  ).observes 'document.path.name'

  collabModeDidChange: (->
    if @get 'collabMode'
      this._enableFirepad()
    else
      this._destroyFirepad()
  ).observes 'collabMode'

  didClickSave: ->
    @get('controller').saveDocument @get('document')

  didClickFind: ->
    if document = @get('document')
      document.set 'findTrigger', true

  didSelectMode: (selectedMode) ->
    @set 'mode', selectedMode

  didSelectTabSize: (selectedTabSize) ->
    @set 'tabSize', selectedTabSize

  didClickSoftTabToggle: ->
    @set 'softTabs', !@get('softTabs')

  didClickCollabToggle: ->
    this.toggleProperty 'collabMode'

  _generateFirepadURL: ->
    firebaseHost = App.get 'config.firebaseHost'
    boxId = App.get 'router.boxIdeController.content.id'
    documentPath = @get 'document.path'

    if documentPath && (absoluteDocumentPath = documentPath.get('absolutePath'))
      pathToken = window.btoa window.unescape(window.encodeURIComponent(absoluteDocumentPath)) # escape unicode and then base64ize it
      "#{firebaseHost}/box/#{boxId}/pad/#{pathToken}"

  _enableFirepad: ->
    cm = @get 'codeMirror'
    documentPath = @get 'document.path'
    firepadURL = this._generateFirepadURL documentPath
    firebaseAuthenticated = App.get 'router.ideCollaborationPaneController.firebaseAuthenticated'

    @set 'firepadEnabling', true

    if firebaseAuthenticated && firepadURL
      firebase = new Firebase firepadURL
      @set 'firebase', firebase

      # check if there are any active users for the pad
      # if not start it as a new session
      this._hasActivePadUsers firebase, (usersPresent) =>
        currentUserName = App.get 'currentUser.username'
        currentUserColor = App.get 'router.ideCollaborationPaneController.userColor'
        content = @get 'document.content'

        cm.setValue ''
        cm.setOption 'readOnly', 'nocursor'

        firepad = Firepad.fromCodeMirror firebase, cm, userId: currentUserName, userColor: currentUserColor
        @set 'firepad', firepad

        firepad.on 'ready', =>
          if firepad.isHistoryEmpty() || !usersPresent
            firepad.setText content
          cm.setOption 'readOnly', false
          cm.refresh()
          this._resetDirtyBitIfContentNotModified content
          this._syncSavedState firebase
          this._notifyCollabEvent()
          @set 'collabMode', true
          @set 'firepadEnabling', false
          App.util.mixpanel 'IDE Collab Mode'
          App.util.mixpanelIncrement 'ide_collab_mode_count'

  _destroyFirepad: ->
    if firepad = @get 'firepad'
      firepad.dispose()
    @set 'firepad', null

  _hasActivePadUsers: (firebase, callback)->
    firebase.child('users').once 'value', (usersSnapshot) ->
      callback usersSnapshot.hasChildren()

  _syncSavedState: (firebase) ->
    document = @get 'document'
    firebase.child('saved').on 'value', (savedSnapshot) ->
      saved = savedSnapshot.val()
      if saved
        document.set 'clean', true
        firebase.child('saved').set null

  _setCollabSavedState: ->
    if firebase = @get 'firebase'
      firebase.child('saved').set true

  _resetDirtyBitIfContentNotModified: (originalContent) ->
    cm = @get 'codeMirror'
    if cm.getValue() == originalContent
      cm.markClean()
      @set 'document.clean', true

  _notifyCollabEvent: ->
    path = @get 'document.path'
    collaborationPaneController = App.get 'router.ideCollaborationPaneController'
    if path && collaborationPaneController
      if absolutePath = path.get 'absolutePath'
        collaborationPaneController.sendMessage absolutePath, App.CollabMessage.TypeCollabMode
