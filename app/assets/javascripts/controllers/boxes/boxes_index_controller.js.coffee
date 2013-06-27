AIO.BoxesIndexController = Em.ObjectController.extend
  contentBinding: 'AIO.router.boxesController'
  confirmTerminateDialog: null
  currentUserBinding: 'AIO.currentUser'

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

  confirmTerminate: (box) ->
    @set 'confirmTerminateDialog', AIO.ConfirmTerminateDialog.create box: box

  terminate: (box) ->
    content = @get 'content'
    box.set 'loading', true
    $.ajax(
      type: 'DELETE'
      dataType: 'json'
      url: "#{box.get 'resourceUrl'}/#{box.get 'id'}"
    ).always ->
      box.set 'loading', false
