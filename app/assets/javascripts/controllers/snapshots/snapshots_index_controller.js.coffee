AIO.SnapshotsIndexController = Em.ArrayController.extend
  refresh: ->
    @set 'content', @get('content').constructor.find()
