TAB_SIZES = [2, 3, 4, 8]

AIO.IdeDocumentView = Em.View.extend
  templateName: 'templates/ide/document'
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

  init: ->
    @_super()
    this.documentPathDidChange()

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
    unless @get('collabMode')
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

  insertCodeMirror: ->
    $codeEditor = @$('.code_editor')
    if $codeEditor.length > 0
      cm = CodeMirror $codeEditor[0],
        theme          : 'vibrant-ink'
        lineNumbers    : true
        mode           : @get 'mode'
        tabSize        : @get 'tabSize'
        indentUnit     : @get 'tabSize'
        indentWithTabs : !@get 'softTabs'
        value          : @get 'document.content'
        extraKeys      :
          # if we are having a selection, Tab will indent it with `indentMore`
          # call, otherwise, if softab is enabled, we will replace tab with
          # space
          'Tab': (cm) =>
            if cm.getSelection().length
              CodeMirror.commands.indentMore cm
            else
              if @get 'softTabs'
                spaces = Array(cm.getOption("indentUnit") + 1).join(" ")
                cm.replaceSelection spaces, "end", "+input"
              else
                CodeMirror.commands.insertTab cm

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
  ).observes 'AIO.router.ideLayoutController.consoleHeight'

  editorWidthDidChange: (->
    if cm = @get 'codeMirror'
      cm.refresh()
  ).observes(
    'AIO.router.ideLayoutController.sidebarWidth',
    'AIO.router.ideLayoutController.collaborationPaneWidth',
    'AIO.router.ideLayoutController.collaborationPaneHidden'
  )

  editorFullscreenToggled: (->
    if cm = @get 'codeMirror'
      cm.refresh()
  ).observes 'AIO.router.ideEditorController.fullscreen'

  focusedDidChange: (->
    if cm = @get 'codeMirror'
      if focused = @get 'document.focused'
        cm.refresh()
        cm.focus()
      else
        @$('textarea')[0].blur()
  ).observes 'document.focused'

  documentPathDidChange: (->
    if fileName = @get 'document.path.name'
      @set 'mode', AIO.FileTypeDetect.detect fileName
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

  didSelectMode: (event) ->
    selectedMode = event.context
    @set 'mode', selectedMode

  didSelectTabSize: (event) ->
    selectedTabSize = event.context
    @set 'tabSize', selectedTabSize

  didClickSoftTabToggle: ->
    @set 'softTabs', !@get('softTabs')

  didClickCollabToggle: ->
    this.toggleProperty 'collabMode'

  _generateFirepadURL: ->
    firebaseHost = AIO.get 'firebaseHost'
    boxId = AIO.get 'router.ideController.content.id'
    documentPath = @get 'document.path'

    if documentPath && (absoluteDocumentPath = documentPath.get('absolutePath'))
      pathToken = window.btoa window.unescape(window.encodeURIComponent(absoluteDocumentPath)) # escape unicode and then base64ize it
      "#{firebaseHost}/box/#{boxId}/pad/#{pathToken}"

  _enableFirepad: ->
    cm = @get 'codeMirror'
    documentPath = @get 'document.path'
    firepadURL = this._generateFirepadURL documentPath
    firebaseAuthenticated = AIO.get 'router.ideCollaborationPaneController.firebaseAuthenticated'

    @set 'firepadEnabling', true

    if firebaseAuthenticated && firepadURL
      firebase = new Firebase firepadURL
      @set 'firebase', firebase

      # check if there are any active users for the pad
      # if not start it as a new session
      this._hasActivePadUsers firebase, (usersPresent) =>
        currentUserId = AIO.get 'currentUser.username'
        currentUserColor = AIO.get 'router.ideCollaborationPaneController.userColor'
        content = @get 'document.content'

        cm.setValue ''
        cm.setOption 'readOnly', 'nocursor'

        firepad = Firepad.fromCodeMirror firebase, cm, userId: currentUserId, userColor: currentUserColor
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
          AIO.util.mixpanel 'IDE Collab Mode'
          AIO.util.mixpanelIncrement 'ide_collab_mode_count'

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
    collaborationPaneController = AIO.get 'router.ideCollaborationPaneController'
    if path && collaborationPaneController
      if absolutePath = path.get 'absolutePath'
        collaborationPaneController.sendMessage absolutePath, AIO.CollabMessage.TypeCollabMode
