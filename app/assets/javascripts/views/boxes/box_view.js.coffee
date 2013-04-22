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
    @get('controller').confirmTerminate @box

  didClickRetryProvisioning: (event) ->
    @box.provision()

  didClickRevealPublicKey: (event) ->
    @box.readDefaultPublicKey()

  didClickAddToGitHub: (event) ->
    @box.addPublicKeyToGitHub()

  didClickLeave: (event) ->
    if window.confirm "Are you sure you want to leave this box?"
      @box.removeCollaborator AIO.get('router.applicationController.currentUser.username'), (removed) =>
        if removed
          this.remove()
