AIO.BoxesIndexView = Em.View.extend
  templateName: 'templates/boxes/index'
  classNames: ['app_page', 'index']
  elementId: 'boxes_index_view'

  didInsertElement: ->
    @get('controller').showIntro()

  didClickNewBox: ->
    AIO.get('router').transitionTo 'boxes.new'

  didClickRefresh: ->
    @get('controller').refresh()
