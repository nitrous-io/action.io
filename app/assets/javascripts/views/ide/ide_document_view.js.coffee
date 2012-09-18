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
    if fileName = @get 'document.path.name'
      @set 'mode', AIO.FileTypeDetect.detect fileName

  didInsertElement: ->
    this.insertCodeMirror()

  willDestroyElement: ->
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
      @set 'codeMirror', CodeMirror $codeEditor[0],
        theme          : 'vibrant-ink'
        lineNumbers    : true
        mode           : @get 'mode'
        tabSize        : @get 'tabSize'
        indentUnit     : @get 'tabSize'
        indentWithTabs : !@get 'softTabs'
        value          : @get 'document.content'
        onChange       : (cm, data) =>
          if @get('document.content') != (content = cm.getValue())
            @set 'document.content', content

  destroyCodeMirror: ->
    if cm = @get 'codeMirror'
      cm.setOption 'onChange', null
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

  didClickSave: ->
    fsSocket = AIO.get 'router.ideController.fsSocket'
    document = @get 'document'
    path = document.get 'path'
    if fsSocket && document && path
      path.incrementProperty 'loadCount'
      fsSocket.writeFile path.get('absolutePath'), document.get('content')

  didSelectMode: (event) ->
    selectedMode = event.context
    @set 'mode', selectedMode

  didSelectTabSize: (event) ->
    selectedTabSize = event.context
    @set 'tabSize', selectedTabSize

  didClickSoftTabToggle: ->
    @set 'softTabs', !@get('softTabs')

