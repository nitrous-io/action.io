AIO.SnapshotsIndexController = Em.ObjectController.extend
  contentBinding: 'box.snapshots'
  box: null

  newSnapshot: ->
    AIO.get('router').transitionTo 'boxes.snapshotsNew', id: @get('box').get('id')

  destroy: (snapshot) ->
    snapshot.deleteRecord()

  cancel: ->
    AIO.get('router').transitionTo 'boxes.index'
