AIO.BoxesIndexController = Em.ArrayController.extend
  sortProperties: ['id']
  didClickNewBox: ->
    this.transitionToRoute 'boxes.new'

  refresh: ->
    AIO.Box.find()

  makeBoxControlRequest: (box, action) ->
    box.set 'loading', true
    $.ajax(
      type: 'PUT'
      dataType: 'json'
      url: "/boxes/#{box.get 'id'}/#{action}"
    ).always(->
      box.set 'loading', false
    ).done (json) ->
      json = json[box.get 'resourceName']
      box.deserialize json

  start: (box) ->
    this.makeBoxControlRequest box, 'start'

  stop: (box) ->
    this.makeBoxControlRequest box, 'stop'

  terminate: (box) ->
    content = @get 'content'
    box.set 'loading', true
    $.ajax(
      type: 'DELETE'
      dataType: 'json'
      url: "boxes/#{box.get 'id'}"
    ).always ->
      box.set 'loading', false
