AIO.MenuItem = Em.Object.extend
  name: null
  macKey: null
  pcKey: null
  url: null
  callback: Em.K
  separator: false

  key: (->
    if AIO.util.isMac()
      @get 'macKey'
    else
      @get 'pcKey'
  ).property 'macKey', 'pcKey'

  keyLabel: (->
    if key = @get 'key'
      key = key[0] if _.isArray key

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
  ).property 'key'

  codeMirrorKey: (->
    if keys = @get 'key'
      keys = [keys] if _.isString keys
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
        ).join '-'
  ).property 'key'

