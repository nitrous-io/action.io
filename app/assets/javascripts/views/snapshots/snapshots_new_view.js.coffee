AIO.SnapshotsNewView = Em.View.extend
  templateName: 'templates/snapshots/new'
  elementId: 'snapshots_new_view'
  classNames: ['app_page', 'new']

  didClickSnapshot: (event) ->
    @get('controller').save()

  didClickCancel: (event) ->
    @get('controller').cancel()
