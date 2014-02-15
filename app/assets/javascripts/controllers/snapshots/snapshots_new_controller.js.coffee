AIO.SnapshotsNewController = Em.ObjectController.extend
  newRecord: (box) ->
    snapshot = AIO.Snapshot.create()
    snapshot.set 'box', box
    @set 'content', snapshot
    snapshot.set 'name', "#{box.get('name')}-#{AIO.util.strftime('%Y%m%d-%H%M')}"

  save: ->
    record = @get 'content'
    record.set 'saving', true
    record.set 'box_id', record.get('box.id')
    record.saveResource()
      .fail (e) ->
        if e.status == 422
          record.set 'errors', $.parseJSON(e.responseText).errors
      .done =>
        AIO.get('router.snapshotsController').addObject record
        AIO.get('router').transitionTo 'boxes.snapshotsIndex', id: @get('content.box.id')
      .always ->
        record.set 'saving', false

  cancel: ->
    AIO.get('router').transitionTo 'boxes.snapshotsIndex', id: @get('content.box.id')

  shutdownBox: ->
    box = @get('content.box')
    box.stop()
