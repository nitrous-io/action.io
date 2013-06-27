AIO.BoxView = Em.View.extend
  templateName: 'templates/boxes/box'
  tagName: 'li'
  box: null
  classNameBindings: ['box.expanded']

  didInsertElement: ->
    @_super()
    @$().find('.explain').tooltip placement: "right"

  didClickBoxTitle: (event) ->
    @get('box').toggleProperty 'expanded'

  didClickIDE: (event) ->
    AIO.get('router').transitionTo 'boxes.ide', id: @get('box').get('id')

  didClickProvisioning: (event) ->
    AIO.get('router').transitionTo 'boxes.provisioning', id: @get('box').get('id')

  didClickStart: (event) ->
    @get('box').start()

  didClickShutDown: (event) ->
    @get('box').stop()

  didClickRestart: (event) ->
    @get('box').restart()

  didClickTerminate: (event) ->
    @get('controller').confirmTerminate @get('box')

  didClickRetryProvisioning: (event) ->
    @get('box').provision()

  didClickRevealPublicKey: (event) ->
    @get('box').readDefaultPublicKey()

  didClickAddToGitHub: (event) ->
    @get('box').addPublicKeyToGitHub()

  didClickChangeSpecs: (event) ->
    AIO.get('router').transitionTo 'boxes.edit', id: @get('box').get('id')

  didClickLeave: (event) ->
    if window.confirm "Are you sure you want to leave this box?"
      @get('box').removeCollaborator AIO.get('currentUser.username'), (removed) =>
        if removed
          this.remove()
