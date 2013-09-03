AIO.PlanView = Em.View.extend
  templateName: 'templates/n2o/plan'
  tagName: 'li'
  classNameBindings: ['selected', ':span3']

  plan: null

  selected: (->
    controller = @get 'controller'
    selectedPlan = controller.get('selectedPlan')
    plan = @get 'plan'

    selectedPlan && (selectedPlan == plan.get('id'))
  ).property 'controller.selectedPlan'

  click: ->
    controller = @get 'controller'
    plan = @get 'plan'
    controller.set 'selectedPlan', plan.get('id')
