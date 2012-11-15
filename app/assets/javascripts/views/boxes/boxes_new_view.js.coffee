AIO.BoxesNewView = Em.View.extend
  regionsBinding: 'AIO.router.regionsController'
  boxTemplatesBinding: 'AIO.router.boxTemplatesController'

  templateName: 'templates/boxes/new'
  classNames: ['app_page', 'new']
  elementId: 'boxes_new_view'

  didClickCreateBox: (event) ->
    mixpanel?.track 'box_new:create'
    @get('controller').save()

  didClickCancel: (event) ->
    mixpanel?.track 'box_new:cancel'
    @get('controller').cancel()
