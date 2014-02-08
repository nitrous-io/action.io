AIO.SnapshotsNewController = Em.ObjectController.extend
  box: null

  hasExistingSnapshot: (->
    @get('content.box.snapshotting') && !@get('content.saving')
  ).property 'content.box.snapshotting', 'content.saving'

  hasBoxError: (->
    @get('hasExistingSnapshot') || @get('content.box.running')
  ).property 'hasExistingSnapshot', 'content.box.running'

  save: ->
    record = @get 'content'
    record.set 'saving', true
    record.box_id = record.get('box.id')
    record.saveResource()
      .fail (e) ->
        if e.status == 422
          record.set 'errors', $.parseJSON(e.responseText).errors
      .done =>
        AIO.get('router.snapshotsController').addObject record
        AIO.get('router').transitionTo 'boxes.snapshotsIndex', boxId: @get('content.box.id')
      .always ->
        record.set 'saving', false

  cancel: ->
    AIO.get('router').transitionTo 'boxes.snapshotsIndex', boxId: @get('content.box.id')

  shutdownBox: ->
    box = @get('content.box')
    box.stop()
