consoleSessionViewNextId = 0

AIO.IdeConsoleSessionView = Em.View.extend
  templateName: 'templates/ide/console_session'
  consoleSessionViewId: null
  consoleSession: null
  classNameBindings: ['consoleSession.active:active']

  init: ->
    @_super.apply this, arguments
    @set 'consoleSessionViewId', ++consoleSessionViewNextId

  didInsertElement: ->
    @_super()
    $(window).bind "orientationchange.ideConsoleSessionView#{@get 'consoleSessionViewId'}", _.bind(@didChangeOrientation, this)

  willDestroyElement: ->
    @_super()
    $(window).unbind "orientationchange.ideConsoleSessionView#{@get 'consoleSessionViewId'}"

  webTerminalPath: (->
    path = AIO.get "router.ideController.content.webTerminalPath"
    if AIO.get "router.ideController.content.term_sync_enabled"
      id = @get "consoleSession.id"
      "#{path}?term_id=#{id}"
    else
      path
  ).property 'AIO.router.ideController.content.webTerminalPath', 'consoleSession.id'

  focusDidChange: (->
    if focused = @get 'consoleSession.focused'
      if iframeWindow = @$('iframe')[0]?.contentWindow
        if activeDocument = AIO.get 'router.ideEditorController.activeTab'
          activeDocument.set 'focused', false
        iframeWindow.focus()
        if iframeWindow.AIO?.page
          iframeWindow.AIO.page.focus()
  ).observes 'consoleSession.focused'

  didChangeOrientation: ->
    window.setTimeout(=>
      if iframe = @$('iframe')[0]
        iframe.style.width = $('body').width() + 'px';
        iframe.contentWindow?.AIO?.page?.term?.sizeToFit?()
        window.setTimeout(->
          iframe.style.width = '100%'
        , 10)
    , 800)
