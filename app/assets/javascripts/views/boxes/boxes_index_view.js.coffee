AIO.BoxesIndexView = Em.View.extend
  templateName: 'templates/boxes/index'
  classNames: ['app_page', 'index']
  elementId: 'boxes_index_view'

  didClickNewBox: ->
    AIO.get('router').transitionTo 'boxes.new'

  didClickRefresh: ->
    @get('controller').refresh()

  didClickBoxTitle: (event) ->
    box = event.context
    box.toggleProperty 'expanded'

  didClickIDE: (event) ->
    box = event.context
    AIO.get('router').transitionTo 'boxes.ide', id: box.get('id')

  didClickProvisioning: (event) ->
    box = event.context
    AIO.get('router').transitionTo 'boxes.provisioning', id: box.get('id')

  didClickStart: (event) ->
    box = event.context
    @get('controller').start box

  didClickShutDown: (event) ->
    box = event.context
    @get('controller').stop box

  didClickTerminate: (event) ->
    box = event.context
    @get('controller').terminate box

