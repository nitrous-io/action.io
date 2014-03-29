App.SelectableTextArea = Em.TextArea.extend
  attributeBindings: ['readonly']

  init: ->
    @_super()
    @set 'readonly', 'readonly'

  click: ->
    @$().select()

