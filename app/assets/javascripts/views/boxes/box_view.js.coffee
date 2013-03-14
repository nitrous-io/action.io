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
    AIO.get('router').transitionTo 'boxes.ide', id: @box.get('id')

  didClickProvisioning: (event) ->
    AIO.get('router').transitionTo 'boxes.provisioning', id: @box.get('id')

  didClickStart: (event) ->
    @box.start()

  didClickShutDown: (event) ->
    @box.stop()

  didClickRestart: (event) ->
    @box.restart()

  didClickTerminate: (event) ->
    @box.terminate()

  didClickRevealPublicKey: (event) ->
    @box.readDefaultPublicKey()

  didClickAddToGitHub: (event) ->
    @box.addPublicKeyToGitHub()
