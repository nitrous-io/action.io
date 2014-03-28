AIO.SnapshotsNewController = Em.ObjectController.extend
  newRecord: (box) ->
    snapshot = AIO.Snapshot.create()
    snapshot.set 'box_id', box.get 'id'
    snapshot.set 'name', "#{box.get('name')}-#{AIO.util.strftime('%Y%m%d-%H%M')}"
    @set 'content', snapshot

  save: ->
    record = @get 'content'
    record.save().then =>
      AIO.get('router').transitionTo 'boxes.snapshotsIndex', id: @get('content.box.id')

  cancel: ->
    AIO.get('router').transitionTo 'boxes.snapshotsIndex', id: @get('content.box.id')

  shutdownBox: ->
    box = @get('content.box')
    box.stop()
