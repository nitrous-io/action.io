AIO.IdeEditorView = Em.View.extend AIO.IdeTabViewMixin,
  templateName: 'templates/ide/editor'
  elementId: 'ide_editor_view'
  socketTimeout: false
  timeoutId: null

  didInsertElement: ->
    @_super()
    $(window).bind 'resize.ideEditorView', _.bind(@resizeTabBarHeight, this)
    this.socketTimeoutCheck()
    this.resizeTabBarHeight()

  willDestroyElement: ->
    @_super()
    this.clearSocketTimeout()
    $(window).unbind 'resize.ideEditorView'

  didClickRefresh: ->
    location.reload()

  socketTimeoutCheck: ->
    timeoutCheck = =>
      @set 'socketTimeout', !(@get 'controller.sftpSocketReady')
    @set 'timeoutId', window.setTimeout(timeoutCheck, 15000)

  clearSocketTimeout: ->
    window.clearTimeout (@get 'timeoutId')

  onSocketReady: (->
    if @get 'controller.sftpSocketReady'
      this.clearSocketTimeout()
  ).observes 'controller.sftpSocketReady'

  resizeTabBarHeight: (->
    Em.run.sync()
    Em.run.next this, ->
      if $header = @$ '> header'
        tabBarHeight = $header.outerHeight()
        $header.css 'margin-top', -tabBarHeight
        @$().css 'padding-top', tabBarHeight
  ).observes 'controller.@each.title'
