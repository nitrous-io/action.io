AIO.IdeView = Em.View.extend
  templateName: 'templates/ide/ide'
  elementId: 'ide_view'

  willInsertElement: ->
    @_super()
    $('html').addClass 'ide'
    $(window).bind 'focus.ideView', ->
      AIO.get('router.ideEditorController').focusActiveTab()

    # prevent accidental backspacing
    $(window).bind 'keydown.ideView', (e) ->
      if e.keyCode == 8 && $(e.target).is('body')
        e.preventDefault()

  willDestroyElement: ->
    @_super()
    $('html').removeClass 'ide'
    $(window).unbind 'focus.ideView'
    $(window).unbind 'keydown.ideView'

  adjustTopPaddingForMainMenu: (->
    mainMenuViewHeight = AIO.get 'router.ideLayoutController.mainMenuViewHeight'
    @$().css 'padding-top', mainMenuViewHeight
  ).observes 'AIO.router.ideLayoutController.mainMenuViewHeight'

