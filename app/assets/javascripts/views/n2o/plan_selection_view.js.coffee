AIO.PlanSelectionView = Em.View.extend
  templateName: 'templates/n2o/plan_selection'

  plansCount: (->
    @get('plans.length')
  ).property 'plans'
