AIO.IdeRootPathView = AIO.IdePathView.extend
  becomeFileManagementDelegate: (->
    if fsSocket = @get 'controller.fsSocket'
      fsSocket.set 'fileManagementDelegate', this
  ).observes 'controller.fsSocket'

  resignFileManagementDelegate: ->
    if fsSocket = @get 'controller.fsSocket'
      fsSocket.set 'fileManagementDelegate', null

  willDestroy: ->
    @_super()
    this.resignFileManagementDelegate()

