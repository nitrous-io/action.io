AIO.IdeSidebarBorderView = Em.View.extend
  elementId: 'sidebar_border'
  minSidebarWidth: null
  widthBinding: 'AIO.router.ideLayoutController.sidebarWidth'

  didInsertElement: ->
    @_super()
    @set 'minSidebarWidth', $('#ide_sidebar_view').innerWidth()

  mouseDown: (event) ->
    $sidebarView = $('#ide_sidebar_view')
    $editorView = $('#ide_editor_view')

    event.preventDefault()

    $('body').on 'mousemove.ideSidebarResize', (event) =>
      newWidth = event.pageX - $sidebarView.offset().left
      minSidebarWidth = @get 'minSidebarWidth'
      if newWidth < minSidebarWidth
        newWidth = minSidebarWidth
        $('body').off 'mousemove.ideSidebarResize'
        $('body').off 'mouseup.ideSidebarResize'

      $sidebarView.css 'width', newWidth
      @set 'width', newWidth

    $('body').on 'mouseup.ideSidebarResize', (event) =>
      @turnOffResizeEvents()
      
  turnOffResizeEvents: ->
    $('body').off 'mousemove.ideSidebarResize'
    $('body').off 'mouseup.ideSidebarResize'

  willDestroyElement: ->
    @_super()
    @turnOffResizeEvents()
