AIO.BoxesIndexView = Em.View.extend
  templateName: 'templates/boxes/index'
  classNames: ['app_page', 'index']
  elementId: 'boxes_index_view'

  didClickNewBox: ->
    mixpanel?.track 'box_index:new'
    AIO.get('router').transitionTo 'boxes.new'

  didClickRefresh: ->
    mixpanel?.track 'box_index:refresh'
    @get('controller').refresh()

  didClickBoxTitle: (event) ->
    mixpanel?.track 'box_index:box_title'
    box = event.context
    box.toggleProperty 'expanded'

  didClickIDE: (event) ->
    mixpanel?.track 'box_index:ide'
    box = event.context
    AIO.get('router').transitionTo 'boxes.ide', id: box.get('id')

  didClickProvisioning: (event) ->
    mixpanel?.track 'box_index:provisioning'
    box = event.context
    AIO.get('router').transitionTo 'boxes.provisioning', id: box.get('id')

  didClickStart: (event) ->
    mixpanel?.track 'box_index:start'
    box = event.context
    @get('controller').start box

  didClickShutDown: (event) ->
    mixpanel?.track 'box_index:shut_down'
    box = event.context
    @get('controller').stop box

  didClickTerminate: (event) ->
    mixpanel?.track 'box_index:terminate'
    box = event.context
    @get('controller').terminate box
