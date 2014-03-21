AIO.SnapshotsIndexController = Em.ObjectController.extend
  contentBinding: 'box.snapshots'
  box: null

  newSnapshot: ->
    AIO.get('router').transitionTo 'boxes.snapshotsNew', id: @get('box').get('id')

  destroy: (snapshot) ->
    snapshot.set 'deleting', true
    content = @get 'content'
    snapshot.destroyResource()
      .done ->
        AIO.get('router.snapshotsController').removeObject snapshot
      .always ->
        snapshot.set 'deleting', false

  cancel: ->
    AIO.get('router').transitionTo 'boxes.index'
