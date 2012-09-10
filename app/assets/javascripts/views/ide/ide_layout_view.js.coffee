AIO.IdeLayoutView = Em.View.extend
  templateName: 'templates/ide/layout'
  elementId: 'ide_layout_view'

  willInsertElement: ->
    $('html').addClass('ide')

  willDestroyElement: ->
    $('html').removeClass('ide')

