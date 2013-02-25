AIO.SnapshotsIndexController = Em.ArrayController.extend
  sortProperties: ['id']

  refresh: ->
    @set 'content', @get('content').constructor.find()

  destroy: (snapshot) ->
    snapshot.deleteRecord()
    @get('store').commit()
