AIO.BoxesSnapshotController = Em.ObjectController.extend
  newRecord: (box_id) ->
    snapshot = AIO.Snapshot.create()
    snapshot.set 'box_id', box_id
    @set 'content', snapshot

  save: ->
    record = @get 'content'
    record.set 'saving', true
    record.saveResource()
      .fail (e) ->
	if e.status == 422
	  record.set 'errors', $.parseJSON(e.responseText).errors
      .done ->
	AIO.get('router').transitionTo 'boxes.index'
      .always ->
	record.set 'saving', false

  cancel: ->
    AIO.get('router').transitionTo 'boxes.index'
