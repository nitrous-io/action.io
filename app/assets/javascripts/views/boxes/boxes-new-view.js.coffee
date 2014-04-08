#= require ../boxes/boxes-control-with-name-generation-view

App.BoxesNewView = App.BoxesControlWithNameGenerationView.extend
  templateName: 'templates/boxes/new'
  elementId: 'boxes_new_view'
  classNames: ['app_page', 'new']

  didSelectSourceSnapshot: (->
    controller = @get 'controller'
    if controller.get 'source_snapshot_id'
      controller.set 'box_template_id', null
    else unless controller.get 'box_template_id'
      controller.set 'box_template_id', App.get('boxTemplates.firstObject.id')
  ).observes 'controller.source_snapshot_id'

  didInsertElement: ->
    @_super.apply this, arguments
    @preselectRegion()
    @$('#box_name')?.focus()

  preselectRegion: (->
    controller = @get 'controller'
    return if controller.get 'region_id' # Don't interfere with user's selection.
    if regionId = App.get 'closestRegionId'
      controller.set 'region_id', regionId
      return
    App.Region.fetchClosestRegion()
  ).observes 'App.closestRegionId'
