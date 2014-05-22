App.BoxhostPlansController = Em.ArrayController.extend
  existingBoxhosts: null # TODO
  selected: null

  errors: null

  actions:
    select: (boxhostPlan) ->
      @transitionToRoute 'boxhost_plan.payment', boxhostPlan
