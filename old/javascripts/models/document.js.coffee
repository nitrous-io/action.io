class AIO.Document extends AIO.Model
  initialize: ->
    this.set(elementId: "document_#{this.cid}")

  defaults:
    codeMirror: null
    theme: 'vibrant-ink'
    mode: 'text/plain'
    tabSize: 2
    softTabs: true
    content: ''

  initCodeMirror: ->
    $document = $('#' + this.get('elementId'))
    if $document.length > 0
      @codeMirror = CodeMirror $document[0],
        theme: this.get('theme')
        lineNumbers: true
        mode: this.get('mode')
        tabSize: this.get('tabSize')
        indentUnit: this.get('tabSize')
        indentWithTabs: !this.get('softTabs')
        value: this.get('content')
        onChange: (codeMirror, data) =>
          this.set({ content: codeMirror.getValue() })

    this.on 'change:mode', (model, val) ->
      model.codeMirror?.setOption('mode', val)

    this.on 'change:tabSize', (model, val) ->
      model.codeMirror?.setOption('tabSize', val)
      model.codeMirror?.setOption('indentUnit', val)

    this.on 'change:softTabs', (model, val) ->
      model.codeMirror?.setOption('indentWithTabs', !val)

    this.on 'change:content', (model, val) ->
      if (codeMirror = model.codeMirror) && codeMirror?.getValue() != val
        codeMirror.setValue(val)

  cleanUp: ->
    @codeMirror?.setOption('onChange', null)
    delete @codeMirror
    this.off()

AIO.Document.setup('documents')

