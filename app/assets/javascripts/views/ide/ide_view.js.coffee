AIO.IdeView = Em.View.extend
  templateName: 'templates/ide/ide'
  elementId: 'ide_view'

  willInsertElement: ->
    @_super()
    $('html').addClass 'ide'

  willDestroyElement: ->
    @_super()
    $('html').removeClass 'ide'

  adjustTopPaddingForMainMenu: (->
    mainMenuHeight = AIO.get 'router.ideLayoutController.mainMenuHeight'
    @$().css 'padding-top', mainMenuHeight
  ).observes 'AIO.router.ideLayoutController.mainMenuHeight'

