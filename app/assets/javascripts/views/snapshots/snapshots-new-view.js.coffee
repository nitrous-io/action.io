App.SnapshotsNewView = Em.View.extend
  templateName: 'templates/snapshots/new'
  elementId: 'snapshots_new_view'
  classNames: ['app_page', 'new', 'settings']

  hasExistingSnapshot: (->
    @get('controller.content.box.snapshotting') && !@get('controller.content.saving')
  ).property 'controller.content.box.snapshotting', 'controller.content.saving'

  hasBoxError: (->
    @get('hasExistingSnapshot') || @get('controller.content.box.running')
  ).property 'hasExistingSnapshot', 'controller.content.box.running'

  didClickSnapshot: (event) ->
    @get('controller').save()

  didClickCancel: (event) ->
    @get('controller').cancel()

  didClickShutDownBox: (event) ->
    @get('controller').shutdownBox()
