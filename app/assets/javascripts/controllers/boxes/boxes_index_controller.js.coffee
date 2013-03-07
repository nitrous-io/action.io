AIO.BoxesIndexController = Em.ArrayController.extend
  sortProperties: ['id']
  didClickNewBox: ->
    this.transitionToRoute 'boxes.new'

  refresh: ->
    AIO.Box.find()

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
