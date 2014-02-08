AIO.SnapshotsIndexController = Em.ObjectController.extend
  contentBinding: 'box.snapshots'
  box: null

  newSnapshot: ->
    AIO.get('router').transitionTo 'boxes.snapshotsNew', boxId: @get('box').get('id')

  destroy: (snapshot) ->
    content = @get 'content'
    snapshot.destroyResource().done ->
      content.removeObject snapshot

  back: ->
    AIO.get('router').transitionTo 'boxes.index'
