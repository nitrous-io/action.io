AIO.IdeConsoleView = Em.View.extend AIO.IdeTabViewMixin,
  templateName: 'templates/ide/console'
  elementId: 'ide_console_view'
  classNameBindings: ['fullscreen']

  fullscreen: false

  didClickFullscreen: ->
    mixpanel?.track 'console:fullscreen', @get('fullscreen')
    @set 'fullscreen', !@get('fullscreen')

  didInsertElement: ->
    mixpanel?.track 'console:insert'
    @_super()
    $(window).bind 'resize.ideConsoleView', _.bind(@resizeTabBarHeight, this)
    this.didClickNew()

  willDestroyElement: ->
    mixpanel?.track 'console:destroy'
    @_super()
    $(window).unbind 'resize.ideConsoleView'

  resizeTabBarHeight: (->
    Em.run.sync()
    Em.run.next this, ->
      if $header = @$ '> header'
        tabBarHeight = $header.outerHeight()
        $header.css 'margin-top', -tabBarHeight
        @$().css 'padding-top', tabBarHeight
  ).observes 'controller.length'
