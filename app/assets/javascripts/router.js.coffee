App.Router.map ->
  @route 'blank'

  @resource 'boxes', ->
    @route 'new'

  @resource 'box', path: '/boxes/:box_id', ->
    @route 'provisioning'
    @route 'resources'
    @route 'domains'
    @resource 'box.snapshots', path: '/snapshots', ->
      @route 'new'
