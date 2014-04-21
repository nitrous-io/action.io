App.BoxSnapshotsView = Em.View.extend
  templateName: 'templates/boxes/box-snapshots'
  elementId: 'box-snapshots-view'
  classNames: ['app_page', 'index', 'settings']

  didClickSnapshot: (event) ->
    @get('controller').newSnapshot()

  didClickDelete: (snapshot) ->
    @get('controller').destroy snapshot

  didClickCancel: (event) ->
    @get('controller').cancel()
