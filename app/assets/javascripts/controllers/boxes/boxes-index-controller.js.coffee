AIO.BoxesIndexController = Em.ObjectController.extend
  confirmTerminateDialog: null
  contentBinding: 'AIO.boxes'
  confirmLeaveDialog: null
  currentUserBinding: 'AIO.currentUser'

  hasForceShutdownBoxes: (->
    return false if AIO.get('subscription.active')
    content = @get('content')
    content.some (box) -> box.get('force_shutdown')
  ).property 'content.@each.force_shutdown', 'AIO.subscription.active'

  refresh: ->
    @get('content').reload()

  confirmTerminate: (box) ->
    @set 'confirmTerminateDialog', AIO.ConfirmTerminateDialog.create box: box

  confirmLeave: (box) ->
    @set 'confirmLeaveDialog', AIO.ConfirmLeaveDialog.create box: box

  leave: (box) ->
    box.removeCollaborator AIO.get('currentUser.username'), =>
      @refresh()
