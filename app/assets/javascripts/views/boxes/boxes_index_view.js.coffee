AIO.BoxesIndexView = Em.View.extend
  templateName: 'templates/boxes/index'
  classNames: ['app_page', 'boxes', 'index']

  didClickTitle: (event) ->
    box = event.context
    box.set 'expanded', !box.get('expanded')

  didClickIDE: (event) ->
    box = event.context
    console.log 'open IDE!'

  didClickTerminate: (event) ->
    box = event.context
    console.log 'terminate'

  didClickNewBox: ->
    AIO.get('router').transitionTo('boxes.new')

  didClickRefresh: ->
    @get('controller').findAll()

