AIO.IdeConsoleView = Em.View.extend AIO.IdeTabViewMixin,
  templateName: 'templates/ide/console'
  elementId: 'ide_console_view'
  classNameBindings: ['fullscreen']

  fullscreen: false

  didClickFullscreen: ->
    @set 'fullscreen', !@get('fullscreen')

  didInsertElement: ->
    @_super()
    $(window).bind 'resize.ideConsoleView', _.bind(@resizeTabBarHeight, this)
    this.didClickNew()

  willDestroyElement: ->
    @_super()
    $(window).unbind 'resize.ideConsoleView'

  resizeTabBarHeight: (->
    Em.run.sync()
    Em.run.next this, ->
      $header = @$ '> header'
      tabBarHeight = $header.outerHeight()
      $header.css 'margin-top', -tabBarHeight
      @$().css 'padding-top', tabBarHeight
  ).observes 'controller.length'

