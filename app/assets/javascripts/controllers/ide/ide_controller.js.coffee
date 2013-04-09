AIO.IdeController = Em.ObjectController.extend
  sftpSocket: null

  initialize: (->
    if content = @get 'content'
      @set 'sftpSocket', sftpSocket = AIO.SftpSocket.create box: content

      router = AIO.get 'router'
      router.get('ideLayoutController').initialize()
      router.get('ideMainMenuController').initialize()
      router.get('ideSidebarController').initialize()
      router.get('ideEditorController').initialize()
      router.get('ideConsoleController').initialize()
      router.get('ideCollaboratorsController').initialize()

      sftpSocket.connect()
    else
      this.reset()
  ).observes 'content'

  reset: ->
    if sftpSocket = @get 'sftpSocket'
      sftpSocket.disconnect()

    router = AIO.get 'router'
    router.get('ideLayoutController').reset()
    router.get('ideMainMenuController').reset()
    router.get('ideConsoleController').reset()
    router.get('ideEditorController').reset()
    router.get('ideSidebarController').reset()
    router.get('ideCollaboratorsController').reset()

    @set 'sftpSocket', null
    @set 'content', null

  redirectToIndexWhenNotRunning: (->
    if content = @get 'content'
      unless content.get('state') == 'running'
        Em.run.next ->
          AIO.get('router').transitionTo 'boxes.index'
  ).observes 'content.state'

