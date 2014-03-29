AIO.OrgsNewView = Em.View.extend
  templateName: 'templates/orgs/new'
  classNames: ['app_page', 'new']
  elementId: 'orgs_new_view'

  didClickCreateOrg: (event) ->
    @get('controller').save()

  didClickCancel: (event) ->
    @get('controller').cancel()


