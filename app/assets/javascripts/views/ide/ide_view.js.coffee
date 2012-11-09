AIO.IdeView = Em.View.extend
  templateName: 'templates/ide/ide'
  elementId: 'ide_view'

  willInsertElement: ->
    @_super()
    $('html').addClass 'ide'

  willDestroyElement: ->
    @_super()
    $('html').removeClass 'ide'

