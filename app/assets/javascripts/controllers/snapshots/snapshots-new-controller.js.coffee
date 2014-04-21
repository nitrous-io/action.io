App.SnapshotsNewController = Em.ObjectController.extend
  newRecord: (box) ->
    snapshot = App.Snapshot.create()
    snapshot.set 'box_id', box.get 'id'
    snapshot.set 'name', "#{box.get('name')}-#{App.util.strftime('%Y%m%d-%H%M')}"
    @set 'content', snapshot

  save: ->
    record = @get 'content'
    record.save().then =>
      App.get('router').transitionTo 'box.snapshots', @get('content.box')

  cancel: ->
    App.get('router').transitionTo 'box.snapshots', @get('content.box')

  shutdownBox: ->
    box = @get('content.box')
    box.stop()
