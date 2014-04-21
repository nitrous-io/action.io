#= require ../boxes/boxes-control-with-name-generation-view

App.BoxesNewView = App.BoxesControlWithNameGenerationView.extend
  templateName: 'templates/boxes/boxes-new'
  elementId: 'boxes_new_view'
  classNames: ['app_page', 'new']

  didSelectSourceSnapshot: (->
    if box = @get 'controller.content'
      if box.get 'source_snapshot_id'
        box.set 'box_template_id', null
      else unless box.get 'box_template_id'
        box.set 'box_template_id', App.get('boxTemplates.firstObject.id')
  ).observes 'controller.content.source_snapshot_id'

  didInsertElement: ->
    @_super.apply this, arguments
    App.util.mixpanel 'Viewed New Box'
    @preselectRegion()
    @$('#box_name')?.focus()

  preselectRegion: (->
    if box = @get 'controller.content'
      return if box.get 'region_id' # Don't interfere with user's selection.
      if regionId = App.get 'closestRegionId'
        box.set 'region_id', regionId
        return
      App.Region.fetchClosestRegion()
  ).observes 'App.closestRegionId'
