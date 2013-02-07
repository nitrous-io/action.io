AIO.BoxesSnapshotController = Em.ObjectController.extend
  save: ->
    console.log "TODO"

  cancel: ->
    AIO.get('router').transitionTo 'boxes.index'
