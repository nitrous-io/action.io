App.DomainsEditView = Em.View.extend
  templateName: 'templates/boxes/domains-edit'
  elementId: 'domains_edit_view'
  classNames: ['app_page', 'edit', 'settings']

  didClickSave: (event) ->
    @get('controller').save()

  didClickCancel: (event) ->
    @get('controller').cancel()
