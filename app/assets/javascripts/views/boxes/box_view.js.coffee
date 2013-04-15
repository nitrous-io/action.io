AIO.BoxView = Em.View.extend
  templateName: 'templates/boxes/box'
  tagName: 'li'
  box: null
  classNameBindings: ['box.expanded']

  didInsertElement: ->
    @_super()
    @$().find('.explain').tooltip placement: "right"

  didClickBoxTitle: (event) ->
    @box.toggleProperty 'expanded'

  didClickIDE: (event) ->
    @get('controller').transitionToRoute 'ide', @box

  didClickProvisioning: (event) ->
    @get('controller').transitionToRoute 'boxes.provisioning', @box

  didClickStart: (event) ->
    @box.start()

  didClickShutDown: (event) ->
    @box.stop()

  didClickRestart: (event) ->
    @box.restart()

  didClickTerminate: (event) ->
    @get('controller').confirmTerminate @box

  didClickRetryProvisioning: (event) ->
    @box.provision()

  didClickRevealPublicKey: (event) ->
    @box.readDefaultPublicKey()

  didClickAddToGitHub: (event) ->
    @box.addPublicKeyToGitHub()
