App.BoxhostPlansController = Em.ArrayController.extend
  existingBoxhosts: null # TODO
  selected: null

  errors: null

  actions:
    select: (boxhostPlan) ->
      @transitionToRoute 'boxhost_plans.payment', queryParams:
        boxhost_plan_id: boxhostPlan.get('id')
