class AIO.MenuItemViewModel extends AIO.ViewModel
  constructor: (name, macKey, windowsKey, linkOrAction) ->
    super()
    @name = ko.observable(name)
    @key = ko.observable(if AIO.isMac() then macKey else windowsKey)
    @href = ko.observable(null)
    if _.isFunction(linkOrAction)
      @action = linkOrAction
    else if _.isString(linkOrAction)
      @action = null
      @href(linkOrAction)

    @keyLabel = ko.computed =>
      if key = @key()
        key = key[0] if _.isArray(key)
        _.map(key.split('+'), (k) ->
          k = switch k
            when 'command'
              "\u2318"
            when 'ctrl'
              "\u2303"
            when 'shift'
              "\u21e7"
            when 'option'
              "\u2325"
            when 'alt'
              "Alt"
            when 'tab'
              "\u21E5"
            when 'backspace'
              "\u232B"
            when 'escape'
              "\u238B"
            else
              k
          k.toUpperCase()
        ).join(' ')

    @codeMirrorKey = ko.computed =>
      if keys = @key()
        keys = [keys] if _.isString(keys)
        _.map keys, (key) ->
          _.map(key.split('+'), (k) ->
            k = switch k
              when 'command'
                'Cmd'
              when 'option'
                'Alt'
              when 'return'
                'Enter'
              when 'pageup'
                'PageUp'
              when 'pagedown'
                'PageDown'
              else
                k
            k.charAt(0).toUpperCase() + k.slice(1)
          ).join('-')

    if (key = @key()) && @action
      Mousetrap?.bind key, (e) =>
        @action()
        false

    if (keys = @codeMirrorKey()) && @action
      if CodeMirror
        if (fallthrough = CodeMirror.keyMap.default.fallthrough) && fallthrough[1] != 'actionio'
          fallthrough.splice(1, 0, 'actionio')
        CodeMirror.keyMap.actionio ||= {}
        for key in keys
          CodeMirror.keyMap.actionio[key] = @action

  action: ->
    AIO.showAlertDialog('Feature Coming Soon', 'This feature is coming soon!')

  __destroy: ->
    if key = @key()
      Mousetrap?.unbind(key)
    if keys = @codeMirrorKey()
      for key in keys
        delete CodeMirror.keyMap.actionio[key]
    super()

