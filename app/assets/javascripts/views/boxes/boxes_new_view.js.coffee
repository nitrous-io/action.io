AIO.BoxesNewView = Em.View.extend
  regionsBinding: 'controller.controllers.regions'
  boxTemplatesBinding: 'controller.controllers.boxTemplates'

  templateName: 'templates/boxes/new'
  classNames: ['app_page', 'new']
  elementId: 'boxes_new_view'

  #TODO: removed all event references here. ember doesnt pass event anymore
  didClickCreateBox: (event) ->
    @get('controller').save()

  didClickCancel: (event) ->
    @get('controller').cancel()

