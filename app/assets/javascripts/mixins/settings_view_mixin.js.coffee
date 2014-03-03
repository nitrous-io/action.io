AIO.SettingsViewMixin = Em.Mixin.create
  didClickResources: (event) ->
    box = event.context
    AIO.get('router').transitionTo 'boxes.resources', id: box.get('id')

  didClickCollaborators: (event) ->
    box = event.context
    AIO.get('router').transitionTo 'boxes.collaborators', id: box.get('id')

  didClickSnapshots: (event) ->
    box = event.context
    AIO.get('router').transitionTo 'boxes.snapshotsIndex', id: box.get('id')

  didClickCancel: (event) ->
    AIO.get('router').transitionTo 'boxes.index'
