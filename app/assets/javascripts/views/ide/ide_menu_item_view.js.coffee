AIO.IdeMenuItemView = Em.View.extend
  templateName: 'templates/ide/menu_item'
  tagName: 'li'
  classNameBindings: ['content.separator:divider', 'content.disabled:disabled']
  content: null

  didInsertElement: ->
    @_super()
    this.bindMousetrapKey()
    this.bindCodeMirrorKey()

  willDestroyElement: ->
    @_super()
    this.unbindMousetrapKey()
    this.unbindCodeMirrorKey()

  click: (event) ->
    content = @get 'content'
    unless content.get('separator') || content.get('disabled')
      if url = content.get 'url'
        AIO.util.mixpanel 'IDE Clicked Out', uri: url
      else if callback = content.get 'callback'
        callback @get('controller')

  bindMousetrapKey: ->
    if key = @get 'content.key'
      Mousetrap.bind key, (event) =>
        this.click()
        false

  unbindMousetrapKey: ->
    if key = @get 'content.key'
      Mousetrap.unbind key

  bindCodeMirrorKey: ->
    if key = @get 'content.codeMirrorKey'
      fallthrough = CodeMirror.keyMap.default.fallthrough
      if _.isString fallthrough
        CodeMirror.keyMap.default.fallthrough = [fallthrough, 'aio']
      else
        if fallthrough && fallthrough[1] != 'aio'
          fallthrough.splice 1, 0, 'aio'
      CodeMirror.keyMap.aio ||= {}
      for k in key
        CodeMirror.keyMap.aio[k] = =>
          this.click()

  unbindCodeMirrorKey: ->
    if key = @get 'content.codeMirrorKey'
      delete CodeMirror.keyMap.aio[k] for k in key

