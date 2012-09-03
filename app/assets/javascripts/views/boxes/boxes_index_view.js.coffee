AIO.BoxesIndexView = Em.View.extend
  templateName: 'templates/boxes/index'
  classNames: ['boxes', 'index']

  didClickSummary: (event) ->
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

