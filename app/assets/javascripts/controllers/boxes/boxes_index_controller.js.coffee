AIO.BoxesIndexController = AIO.ResourceController.extend
  resourceType: AIO.Box
  jsonRoot: 'boxes'

  didClickNewBox: ->
    this.transitionToRoute 'boxes.new'

  refresh: ->
    this.findAll()

  start: (box) ->
    box.start()

  stop: (box) ->
    box.stop()

  terminate: (box) ->
    box.terminate()

  restart: (box) ->
    box.restart()

  revealPublicKey: (box) ->
    box.readDefaultPublicKey()

  addToGithub: (box) ->
    box.addPublicKeyToGitHub()
