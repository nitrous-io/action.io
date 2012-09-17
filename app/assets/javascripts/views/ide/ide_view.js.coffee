AIO.IdeView = Em.View.extend
  templateName: 'templates/ide/ide'
  elementId: 'ide_view'

  willInsertElement: ->
    $('html').addClass 'ide'

  willDestroyElement: ->
    $('html').removeClass 'ide'

