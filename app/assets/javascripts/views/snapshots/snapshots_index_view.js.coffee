AIO.SnapshotsIndexView = Em.View.extend AIO.SettingsViewMixin,
  templateName: 'templates/snapshots/index'
  elementId: 'snapshots_index_view'
  classNames: ['app_page', 'index', 'settings']

  didClickSnapshot: (event) ->
    @get('controller').newSnapshot()

  didClickDelete: (event) ->
    snapshot = event.context
    @get('controller').destroy snapshot

  didClickBack: (event) ->
    @get('controller').back()
