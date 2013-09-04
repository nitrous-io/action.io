AIO.IdeView = Em.View.extend
  templateName: 'templates/ide/ide'
  elementId: 'ide_view'
  classNames: 'ide_view'

  shouldShowMacAnnouncement: (->
    !AIO.get('isChromeWebView') && AIO.util.IsMac && !AIO.localStorage.get('clickedMacAnnouncement')
  ).property 'AIO.isChromeWebView'

  didClickMacAnnouncement: ->
    AIO.localStorage.set('clickedMacAnnouncement', true)
    $('.top-announcement').remove()
    window.open("/mac", "_blank")

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

