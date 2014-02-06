AIO.SnapshotsNewController = Em.ObjectController.extend
  cancel: ->
    AIO.get('router').transitionTo 'boxes.index'
