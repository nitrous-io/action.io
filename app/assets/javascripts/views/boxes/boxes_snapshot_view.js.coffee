AIO.BoxesSnapshotView = Em.View.extend
  templateName: 'templates/boxes/snapshot'
  classNames: ['app_page', 'snapshot']
  elementId: 'boxes_snapshot_view'

  didClickCreateBox: (event) ->
    @get('controller').save()

  didClickCancel: (event) ->
    @get('controller').cancel()



