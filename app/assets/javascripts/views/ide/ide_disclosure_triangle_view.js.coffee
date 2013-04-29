AIO.IdeDisclosureTriangleView = Em.View.extend
  tagName: 'i'
  path: null
  classNameBindings: ['path.expanded:icon-caret-down:icon-caret-right']

  click: (event) ->
    controller = @get 'controller'
    controller.openPath @get('path')

  doubleClick: (event) ->
    event.preventDefault()
    event.stopPropagation()
