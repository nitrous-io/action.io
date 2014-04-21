#= require ./boxes-control-view

App.BoxesControlWithNameGenerationView = App.BoxesControlView.extend
  didSelectBoxTemplate: (->
    controller = @get 'controller'
    if box = @controller.get 'content'
      boxTemplateId = box.get 'box_template_id'
      box.set('source_snapshot_id', null) if boxTemplateId
      return if controller.get('boxNameIsDirty')
      name = App.RandomBoxNameGenerator.generate(box.get 'boxTemplate.runtime')
      box.set 'name', name
  ).observes 'controller.content.box_template_id'
