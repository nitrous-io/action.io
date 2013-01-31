AIO.IdeSidebarBorderView = Em.View.extend
  elementId: 'sidebar_border'
  minSidebarWidth: null

  didInsertElement: ->
    @_super()
    @set 'minSidebarWidth', $('#ide_sidebar_view').width()

  mouseDown: ->
    $sidebarView = $('#ide_sidebar_view')
    $editorView = $('#ide_editor_view')
    $('body').bind 'mousemove.sidebar-resize', (event) =>
      newWidth = event.pageX - $sidebarView.offset().left
      if newWidth > @get 'minSidebarWidth'
        $sidebarView.css 'width', newWidth
        $editorView.css 'paddingLeft', (newWidth + 4)

    $('body').bind 'mouseup.sidebar-resize', (event) =>
      $('body').unbind 'mousemove.sidebar-resize'
      $('body').unbind 'mouseup.sidebar-resize'
