AIO.SnapshotsIndexView = Em.View.extend
  templateName: 'templates/snapshots/index'
  elementId: 'snapshots_index_view'
  classNames: ['app_page', 'index']

  didClickSnapshot: (event) ->
    @get('controller').newSnapshot()

  didClickBack: (event) ->
    @get('controller').back()
