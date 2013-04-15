AIO.BoxesIndexView = Em.View.extend
  templateName: 'templates/boxes/index'
  classNames: ['app_page', 'index']
  elementId: 'boxes_index_view'

  didClickNewBox: ->
    @get('controller').transitionToRoute 'boxes.new'

  didClickRefresh: ->
    @get('controller').refresh()
