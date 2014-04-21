App.BoxSnapshotsController = Em.ObjectController.extend
  newSnapshot: ->
    App.get('router').transitionTo 'boxes.snapshotsNew', id: @get('box').get('id')

  destroy: (snapshot) ->
    snapshot.deleteRecord()

  cancel: ->
    App.get('router').transitionTo 'boxes.index'
