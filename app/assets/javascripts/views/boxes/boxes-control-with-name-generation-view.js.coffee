#= require ./boxes-control-view

App.BoxesControlWithNameGenerationView = App.BoxesControlView.extend
  didSelectBoxTemplate: (->
    controller = @get 'controller'
    boxTemplateId = controller.get 'box_template_id'
    controller.set('source_snapshot_id', null) if boxTemplateId
    return if controller.get('boxNameIsDirty')
    name = App.RandomBoxNameGenerator.generate(controller.get 'boxTemplate.runtime')
    controller.set 'name', name
  ).observes 'controller.box_template_id'
