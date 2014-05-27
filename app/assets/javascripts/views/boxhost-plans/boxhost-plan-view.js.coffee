App.BoxhostPlanView = Em.View.extend
  templateName: 'templates/boxhost-plans/boxhost-plan'
  tagName: 'li'
  classNameBindings: ['selected', 'readonly']

  boxhostPlan: null

  selected: (->
    controller = @get 'controller'
    selected = controller.get('selected')

    selected && selected.get('id') == @get('boxhostPlan.id')
  ).property 'controller.selected'

  click: ->
    controller = @get 'controller'
    controller.set 'selected', @get('boxhostPlan')
