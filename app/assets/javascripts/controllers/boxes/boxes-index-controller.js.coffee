AIO.BoxesIndexController = Em.ObjectController.extend
  contentBinding: 'AIO.router.boxesController'
  confirmTerminateDialog: null
  confirmLeaveDialog: null
  currentUserBinding: 'AIO.currentUser'

  hasForceShutdownBoxes: (->
    return false if AIO.get('subscription.active')
    content = @get('content')
    content.some (box) -> box.get('force_shutdown')
  ).property 'content.@each.force_shutdown', 'AIO.subscription.active'

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

  confirmLeave: (box) ->
    @set 'confirmLeaveDialog', AIO.ConfirmLeaveDialog.create box: box

  terminate: (box) ->
    content = @get 'content'
    box.set 'loading', true
    $.ajax(
      type: 'DELETE'
      dataType: 'json'
      url: "#{box.get 'resourceUrl'}/#{box.get 'id'}"
    ).always ->
      box.set 'loading', false

  leave: (box) ->
    box.removeCollaborator AIO.get('currentUser.username'), =>
      this.refresh()
