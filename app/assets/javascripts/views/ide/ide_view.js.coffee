AIO.IdeView = Em.View.extend
  templateName: 'templates/ide/ide'
  elementId: 'ide_view'

  didInsertElement: ->
    this.addObserver 'controller.controllers.ideLayout.mainMenuViewHeight',
      this, this.adjustTopPaddingForMainMenu

  willInsertElement: ->
    @_super()
    $('html').addClass 'ide'

  willDestroyElement: ->
    @_super()
    $('html').removeClass 'ide'

  adjustTopPaddingForMainMenu: ->
    mainMenuViewHeight = @get 'controller.controllers.ideLayout.mainMenuViewHeight'
    @$().css 'padding-top', mainMenuViewHeight
