AIO.BoxesIndexView = Em.View.extend
  templateName: 'templates/boxes/index'
  classNames: ['app_page', 'index']
  elementId: 'boxes_index_view'

  didClickTitle: (event) ->
    box = event.context
    box.set 'expanded', !box.get('expanded')

  didClickIDE: (event) ->
    box = event.context
    AIO.get('router').transitionTo('boxes.ide', id: box.get('id'))

  didClickStart: (event) ->
    box = event.context
    # TODO: start

  didClickShutDown: (event) ->
    box = event.context
    # TODO: shut down

  didClickSuspend: (event) ->
    box = event.context
    # TODO: start

  didClickResume: (event) ->
    box = event.context
    # TODO: resume

  didClickTerminate: (event) ->
    box = event.context
    # TODO: terminate

  didClickNewBox: ->
    AIO.get('router').transitionTo('boxes.new')

  didClickRefresh: ->
    @get('controller').findAll()

