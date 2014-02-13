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

  didClickTerminal: (event) ->
    AIO.get('router').transitionTo 'boxes.terminal', id: @get('box').get('id')

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

  didClickSettings: (event) ->
    AIO.get('router').transitionTo 'boxes.edit', id: @get('box').get('id')

  didClickViewSnapshots: (event) ->
    AIO.get('router').transitionTo 'boxes.snapshotsIndex', boxId: @get('box').get('id')

  didClickLeave: (event) ->
    @get('controller').confirmLeave @get('box')

  didClickBoxShutdownUpgrade: (event) ->
    AIO.util.mixpanel 'Clicked Box Shutdown Upgrade'
    AIO.get('router').transitionTo 'n2o.upgrade'

  didClickCPUShareUpgrade: (event) ->
    AIO.util.mixpanel 'Clicked CPU Share Upgrade'
    AIO.get('router').transitionTo 'n2o.upgrade'
