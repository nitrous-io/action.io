App.BoxhostPlansController = Em.ArrayController.extend
  existingBoxhosts: null # TODO
  selected: null

  errors: null

  actions:
    select: (boxhostPlan) ->
      # FIXME
      # 1. This should actually transition to payment screen first, e.g.
      #    @transitionToRoute 'boxhost_plan.payment', boxhostPlan
      # 2. On the payment screen, the user can pick multiple boxhosts at the
      #    same time, so we'll have to create multiple Boxhost records.
      # 3. Use server-side validation to ensure that we only create records for
      #    boxhosts matching what the user actually paid for.
      boxhostPlan.subscribe().then =>
        @transitionToRoute 'boxhosts.pending'
