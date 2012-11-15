AIO.IdeEditorView = Em.View.extend AIO.IdeTabViewMixin,
  templateName: 'templates/ide/editor'
  elementId: 'ide_editor_view'
  socketTimeout: false
  timeoutId: null

  willInsertElement: ->
    this.socketTimeoutCheck()

  didInsertElement: ->
    @_super()
    $(window).bind 'resize.ideEditorView', _.bind(@resizeTabBarHeight, this)
    this.resizeTabBarHeight()

  willDestroyElement: ->
    @_super()
    $(window).unbind 'resize.ideEditorView'

  didClickRefresh: ->
    location.reload()

  socketTimeoutCheck: ->
    timeoutCheck = =>
      @set 'socketTimeout', !(@get 'controller.sftpSocketReady')
    @set 'timeoutId', window.setTimeout(timeoutCheck, 15000)

  clearSocketTimeout: (->
    if @get 'controller.sftpSocketReady'
      window.clearTimeout (@get 'timeoutId')
  ).observes 'controller.sftpSocketReady'

  resizeTabBarHeight: (->
    Em.run.sync()
    Em.run.next this, ->
      if $header = @$ '> header'
        tabBarHeight = $header.outerHeight()
        $header.css 'margin-top', -tabBarHeight
        @$().css 'padding-top', tabBarHeight
  ).observes 'controller.@each.title'
