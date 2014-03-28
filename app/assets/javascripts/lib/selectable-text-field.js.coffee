AIO.SelectableTextField = Em.TextField.extend
  attributeBindings: ['readonly']

  init: ->
    @_super()
    @set 'readonly', 'readonly'

  click: ->
    @$().select()

