#AIO.BoxesSnapshotController = Em.ObjectController.extend
#  resourceType: AIO.Snapshot
#  jsonRoot: 'snapshots'
#  box: null

#  # hack to workaround ember-rest inability to handle dynamic resourceUrl
#  _resourceUrl: () ->
#    "/boxes/#{boxId}/documents" if boxId = @get('box.id')

#  newRecord: () ->
#    snapshot = AIO.Snapshot.create()
#    snapshot.set 'box_id', box.id
#    @set 'content', snapshot

#  save: ->
#    record = @get 'content'
#    record.set 'saving', true
#    record.saveResource()
#      .fail (e) ->
#  if e.status == 422
#    record.set 'errors', $.parseJSON(e.responseText).errors
#      .done ->
#  AIO.get('router').transitionTo 'boxes.index'
#      .always ->
#  record.set 'saving', false

#  cancel: ->
#    AIO.get('router').transitionTo 'boxes.index'
