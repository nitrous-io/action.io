AIO.SnapshotsIndexController = Em.ArrayController.extend
  refresh: ->
    @set 'content', @get('content').constructor.find()

  destroy: (snapshot) ->
    snapshot.deleteRecord()
    @get('store').commit()
