AIO.BoxesIndexController = AIO.ResourceController.extend
  resourceType: AIO.Box
  jsonRoot: 'boxes'

  didClickNewBox: ->
    this.transitionTo 'boxes.new'

  refresh: ->
    @get('content').findAll()

  makeBoxControlRequest: (box, action) ->
    box.set 'loading', true
    $.ajax(
      type: 'PUT'
      dataType: 'json'
      url: "#{box.get 'resourceUrl'}/#{box.get 'id'}/#{action}"
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
      url: "#{box.get 'resourceUrl'}/#{box.get 'id'}"
    ).always ->
      box.set 'loading', false

