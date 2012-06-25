class AIO.Document extends AIO.Model
  initialize: ->
    this.set
      codeMirror: null
      elementId: "document_#{this.cid}"
      theme: 'vibrant-ink'
      mode: 'text/plain'
      tabSize: 2
      softTabs: true
      content: ''

  initCodeMirror: ->
    $document = $('#' + this.get('elementId'))
    @codeMirror = CodeMirror $document[0],
      theme: this.get('theme')
      lineNumbers: true
      mode: this.get('mode')
      tabSize: this.get('tabSize')
      indentUnit: this.get('tabSize')
      indentWithTabs: !this.get('softTabs')
      value: this.get('content')

    this.on 'change:mode', (model, val) ->
      model.codeMirror?.setOption('mode', val)

    this.on 'change:tabSize', (model, val) ->
      model.codeMirror?.setOption('tabSize', val)
      model.codeMirror?.setOption('indentUnit', val)

    this.on 'change:softTabs', (model, val) ->
      model.codeMirror?.setOption('indentWithTabs', !val)

  setContent: (content) ->
    this.set(content: content)
    @codeMirror?.setValue(content)

  content: ->
    @codeMirror?.getValue() || ''

AIO.Document.setup('documents')

