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
    $('#console_border').draggable
      containment: 'parent'
      axis: 'y'
      drag: _.bind(@onBorderDrag, this)
      stop: _.bind(@onBorderDrag, this)
    this.didClickNew()

  willDestroyElement: ->
    @_super()
    $(window).unbind 'resize.ideConsoleView'
    $('#console_border').draggable 'destroy'

  onBorderDrag: (event) ->
    $this = @$()
    $consoleBorder = $ '#console_border'
    $editorView = $ '#ide_editor_view'
    $sidebarView = $ '#ide_sidebar_view'
    $codeMirror = $editorView.find '.CodeMirror'
    $codeMirrorScrollbar = $codeMirror.find '.CodeMirror-scrollbar'
    consoleBorderHeight = $consoleBorder.outerHeight()
    y = $consoleBorder.offset().top
    newHeight = $(window).height() - y - consoleBorderHeight
    $this.css 'height', newHeight
    $editorView.css 'padding-bottom', newHeight + consoleBorderHeight
    $codeMirrorScrollbar.css 'height', $codeMirror.height()
    $sidebarView.css 'padding-bottom', newHeight + consoleBorderHeight

  resizeTabBarHeight: (->
    Em.run.sync()
    Em.run.next this, ->
      if $header = @$ '> header'
        tabBarHeight = $header.outerHeight()
        $header.css 'margin-top', -tabBarHeight
        @$().css 'padding-top', tabBarHeight
  ).observes 'controller.length'

