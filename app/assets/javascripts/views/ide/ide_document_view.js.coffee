TAB_SIZES = [2, 3, 4, 8]

AIO.IdeDocumentView = Em.View.extend
  templateName: 'templates/ide/document'
  classNames: ['ide_document_view']

  document: null
  codeMirror: null
  firepad: null
  collaborating: false

  mode: 'text/plain'
  softTabs: true
  tabSize: 2

  init: ->
    @_super()
    this.documentPathDidChange()

  didInsertElement: ->
    @_super()
    this.insertCodeMirror()

  willDestroyElement: ->
    @_super()
    this.destroyCodeMirror()

  modeName: (->
    CodeMirror.MODES[@get('mode')]
  ).property 'mode'

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

      cm.on "change", (cm, data) =>
        if !this.isDestroyed
          if @get('document.content') != (content = cm.getValue())
            @set 'document.content', content

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
    this._destroyFirepad()

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

  consoleHeightChanged: (->
    if cm = @get 'codeMirror'
      cm.refresh()
  ).observes 'AIO.router.ideLayoutController.consoleHeight'

  sidebarWidthChanged: (->
    if cm = @get 'codeMirror'
      cm.refresh()
  ).observes 'AIO.router.ideLayoutController.sidebarWidth'

  focusedDidChange: (->
    if cm = @get 'codeMirror'
      if focused = @get 'document.focused'
        cm.focus()
      else
        @$('textarea')[0].blur()
  ).observes 'document.focused'

  documentPathDidChange: (->
    if fileName = @get 'document.path.name'
      @set 'mode', AIO.FileTypeDetect.detect fileName
  ).observes 'document.path.name'

  documentClosedWithoutSaving: (->
    if @get 'document.closedWithoutSaving'
      if firepad = @get 'firepad'
        firepad.setText @get( 'document.lastSavedContent' )
  ).observes 'document.closedWithoutSaving'

  didClickSave: ->
    @get('controller').saveDocument @get('document')

  didSelectMode: (event) ->
    selectedMode = event.context
    @set 'mode', selectedMode

  didSelectTabSize: (event) ->
    selectedTabSize = event.context
    @set 'tabSize', selectedTabSize

  didClickSoftTabToggle: ->
    @set 'softTabs', !@get('softTabs')

  didClickCollaborateToggle: ->
    cm = @get 'codeMirror'
    if !@get('collaborating')
      if @get('document.path') != null && @get('document.clean')
        cm.setOption 'value', ''
        cm.setOption 'readOnly', 'nocursor'
        this._enableFirepad cm
      else
        window.alert 'You must save the file before collaborating.'
    else
      this._destroyFirepad()

  _enableFirepad: (codeMirror) ->
    # Firepad can be enabled only for existing files
    documentPath = @get('document.path')
    firepadRef = AIO.util.generateFirepadRef documentPath
    createSession = false

    if AIO.get('firebaseAuthenticated') && firepadRef
      padRef = new Firebase firepadRef

      # check if there are any active users for the pad
      # if not start it as a new session
      this._hasActivePadUsers padRef, (result) =>
        createSession = !result
      
        firepad = Firepad.fromCodeMirror padRef, codeMirror
        @set 'firepad', firepad

        firepad.on 'ready', =>
          if firepad.isHistoryEmpty() || createSession
            firepad.setText @get('document.lastSavedContent')
          codeMirror.setOption 'readOnly', false
          codeMirror.refresh()
          @set 'collaborating', true

  _destroyFirepad: ->
    if firepad = @get 'firepad'
      firepad.dispose()
    @set 'collaborating', false
    @set 'firepad', null

  _hasActivePadUsers: (ref, callback)->
    ref.child('users').once 'value', (usersSnapshot) ->
      callback(usersSnapshot.hasChildren())

