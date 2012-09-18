AIO.IdeConsoleView = Em.View.extend AIO.IdeTabViewMixin,
  templateName: 'templates/ide/console'
  elementId: 'ide_console_view'
  classNameBindings: ['fullscreen']

  fullscreen: false

  didClickFullscreen: ->
    @set 'fullscreen', !@get('fullscreen')

