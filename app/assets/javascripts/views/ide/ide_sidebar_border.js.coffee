AIO.IdeSidebarBorderView = Em.View.extend
  elementId: 'sidebar_border'
  minSidebarWidth: null

  didInsertElement: ->
    @_super()
    @set 'minSidebarWidth', $('#ide_sidebar_view').innerWidth()

  mouseDown: (event) ->
    $sidebarView = $('#ide_sidebar_view')
    $editorView = $('#ide_editor_view')

    event.preventDefault()

    $('body').on 'mousemove.sidebar-resize', (event) =>
      newWidth = event.pageX - $sidebarView.offset().left
      minSidebarWidth = @get 'minSidebarWidth'
      if newWidth < minSidebarWidth
        newWidth = minSidebarWidth
        $('body').off 'mousemove.sidebar-resize'
        $('body').off 'mouseup.sidebar-resize'

      $sidebarView.css 'width', newWidth
      $editorView.css 'paddingLeft', (newWidth + 4)

    $('body').on 'mouseup.sidebar-resize', (event) =>
      $('body').off 'mousemove.sidebar-resize'
      $('body').off 'mouseup.sidebar-resize'
