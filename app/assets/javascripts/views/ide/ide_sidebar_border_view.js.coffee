AIO.IdeSidebarBorderView = Em.View.extend
  elementId: 'sidebar_border'
  minSidebarWidth: null
  widthBinding: 'AIO.router.ideLayoutController.sidebarWidth'

  mouseDown: (event) ->
    event.preventDefault()

    $sidebarView = $('#ide_sidebar_view')
    $body = $('body')

    minSidebarWidth = 240

    $body.on 'mousemove.ideSidebarResize', (event) =>
      newWidth = event.pageX - $sidebarView.offset().left
      if newWidth < minSidebarWidth
        newWidth = minSidebarWidth
        $body.off 'mousemove.ideSidebarResize'
        $body.off 'mouseup.ideSidebarResize'

      $sidebarView.css 'width', newWidth
      @set 'width', newWidth

    $body.on 'mouseup.ideSidebarResize', (event) =>
      this.turnOffResizeEvents()

  turnOffResizeEvents: ->
    $('body').off 'mousemove.ideSidebarResize'
    $('body').off 'mouseup.ideSidebarResize'

  willDestroyElement: ->
    @_super()
    this.turnOffResizeEvents()
