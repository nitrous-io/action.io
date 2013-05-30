AIO.BoxesTourView = AIO.TourView.extend
  steps: [
    {
      target: '#new_box_btn'
      content: 'Boxes are individual development environments, you can create multiple boxes with paid accounts. Click "New Box" to get started!'
      placement: 'bottom'
    },
    {
      target: 'ul.stacks'
      content: 'We have box templates for Ruby, Python, NodeJS, Go, and are adding more templates soon. You can always terminate a box and create a new box from a different template later.'
      placement: 'left'
    },
    {
      target: '#box_region_id'
      content: "Choose a box region closest to where you regularly live / work. This will reduce network latency to ensure things are lightning fast."
      placement: 'right'
    }
  ]

  didClickNext: ->
    @_super()
    controller = @get 'controller'
    if controller.get('step') == 0
      AIO.get('router').transitionTo 'boxes.new'
