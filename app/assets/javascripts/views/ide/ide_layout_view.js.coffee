AIO.IdeLayoutView = Em.View.extend
  templateName: 'templates/ide/layout'
  classNames: ['ide', 'layout']

  willInsertElement: ->
    $('html').addClass('ide')

  willDestroyElement: ->
    $('html').removeClass('ide')

