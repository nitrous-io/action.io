TAB_SIZES = [2, 3, 4, 8]

AIO.IdeDocumentView = Em.View.extend
  templateName: 'templates/ide/document'
  classNames: ['ide_document_view']

  document: null
  codeMirror: null

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

      if @get('document.path') != null
        cm.setOption 'readOnly', 'nocursor'
        this._enableFirepad cm
      else
        cm.setOption 'value', @get('document.content')

      cm.on "change", (cm, data) =>
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

  _enableFirepad: (codeMirror) ->
    # Firepad can be enabled only for existing files
    documentPath = @get('document.path')
    
    if ( AIO.get 'firebaseAuthenticated' ) &&
       ( firepadRef = AIO.util.generateFirepadRef(documentPath) )

      padRef = new Firebase(firepadRef)
      firepad = Firepad.fromCodeMirror padRef, codeMirror
      firepad.on 'ready', =>
        if firepad.isHistoryEmpty()
          firepad.setText @get( 'document.content' )
        codeMirror.setOption 'readOnly', false
        codeMirror.refresh()
