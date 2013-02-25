AIO.SnapshotsNewController = Em.ObjectController.extend
  box: null

  save: ->
    record = @get 'content'
    unless errors = record.validate()
      @get('store').commit()
      record.addObserver 'id', this, 'afterCreate'

  afterCreate: ->
    @get('content').removeObserver 'id', this, 'afterCreate'
    this.transitionToRoute 'snapshots.processing', @get('content')

  cancel: ->
    this.transitionToRoute 'snapshots.index'
