AIO.IdeController = Em.ObjectController.extend
  needs: ['ide', 'ideLayout', 'ideMainMenu', 'ideSidebar', 'ideEditor', 'ideConsole', 'ideCollaborators']
  model: null
  sftpSocket: null

  initialize: (->
    if content = @get 'content'
      @set 'sftpSocket', sftpSocket = AIO.SftpSocket.create box: content

      controllers = @get 'controllers'
      controllers.get('ideLayout').initialize()
      controllers.get('ideMainMenu').initialize()
      controllers.get('ideSidebar').initialize()
      controllers.get('ideEditor').initialize()
      controllers.get('ideConsole').initialize()
      controllers.get('ideCollaborators').initialize()

      sftpSocket.connect()
    else
      this.reset()
  ).observes 'content'

  reset: ->
    if sftpSocket = @get 'sftpSocket'
      sftpSocket.disconnect()

    controllers = @get 'controllers'
    controllers.get('ideLayout').reset()
    controllers.get('ideMainMenu').reset()
    controllers.get('ideSidebar').reset()
    controllers.get('ideEditor').reset()
    controllers.get('ideConsole').reset()
    controllers.get('ideCollaborators').reset()

    @set 'sftpSocket', null
    @set 'content', null

  redirectToIndexWhenNotRunning: (->
    if content = @get 'content'
      unless content.get('state') == 'running'
        Em.run.next => @transitionToRoute 'boxes.index'
  ).observes 'content.state'

