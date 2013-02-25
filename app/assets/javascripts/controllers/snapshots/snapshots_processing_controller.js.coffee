AIO.SnapshotsProcessingController = Em.ObjectController.extend
  redirectToIndexWhenSnapshotted: (->
    if content = @get('content')
      if content.get('state') == 'snapshotted'
        Em.run.next =>
          this.transitionToRoute 'snapshots.index'
  ).observes 'content.state'
