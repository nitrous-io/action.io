AIO.IdeConsoleSessionView = Em.View.extend
  templateName: 'templates/ide/console_session'
  consoleSession: null
  classNameBindings: ['consoleSession.active:active']

  focusDidChange: (->
    if focused = @get 'consoleSession.focused'
      if iframeWindow = @$('iframe')[0].contentWindow
        if activeDocument = AIO.get 'router.ideEditorController.activeTab'
          activeDocument.set 'focused', false
        iframeWindow.focus()
        if iframeWindow.AIO && iframeWindow.AIO.page
          iframeWindow.AIO.page.focus()
  ).observes 'consoleSession.focused'

