AIO.SnapshotsRestoreController = Em.ObjectController.extend
  restore: ->
    snapshot = @get 'content'
    snapshot.set 'isLoading', true
    $.ajax(
      type: 'PUT'
      data:
        box_id: snapshot.get('box.id')
      dataType: 'json'
      url: "/snapshots/#{snapshot.get('id')}/restore"
    ).always(->
      snapshot.set 'isLoading', false
    ).done =>
      this.transitionToRoute 'boxes.index'

  cancel: ->
    this.transitionToRoute 'snapshots.index'
