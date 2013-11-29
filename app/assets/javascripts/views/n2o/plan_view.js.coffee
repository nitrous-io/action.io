AIO.PlanView = Em.View.extend
  templateName: 'templates/n2o/plan'
  tagName: 'li'
  classNameBindings: ['selected', ':span3']

  plan: null

  selected: (->
    controller = @get 'controller'
    selectedPlan = controller.get('selectedPlan')
    plan = @get 'plan'

    selectedPlan && (selectedPlan.get('id') == plan.get('id'))
  ).property 'controller.selectedPlan'

  isCurrentPlan: (->
    controller = @get 'controller'
    currentPlan = controller.get 'currentPlan'
    plan = @get 'plan'

    currentPlan && (currentPlan.get('id') == plan.get('id'))
  ).property 'controller.currentPlan'

  notStartPlan: (->
    @get('plan.name') != 'Start'
  ).property 'plan.name'

  click: ->
    controller = @get 'controller'
    plan = @get 'plan'
    controller.set 'selectedPlan', plan
