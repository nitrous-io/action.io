AIO.BoxesIndexView = Em.View.extend
  templateName: 'templates/boxes/index'
  classNames: ['app_page', 'index']
  elementId: 'boxes_index_view'

  didClickNewBox: ->
    AIO.get('router').transitionTo 'boxes.new'
    if tourController = AIO.get 'router.tourController'
      tourController.nextStep()

  didClickRefresh: ->
    @get('controller').refresh()
