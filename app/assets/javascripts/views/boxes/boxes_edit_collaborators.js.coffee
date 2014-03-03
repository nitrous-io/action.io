AIO.BoxesEditCollaboratorsView = Em.View.extend AIO.SettingsViewMixin,
  templateName: 'templates/boxes/edit_collaborators'
  classNames: ['app_page', 'edit', 'settings']
  elementId: 'boxes_edit_collaborators_view'

  didClickBack: (event) ->
    @get('controller').back()
