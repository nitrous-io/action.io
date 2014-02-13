AIO.AbTestMixin = Em.Mixin.create
  init: ->
    @_super()
    @set 'templateName', AIO.get('abTestAlternatives')["#{@constructor}"]
