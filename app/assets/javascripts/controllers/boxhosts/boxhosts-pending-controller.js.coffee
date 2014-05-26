App.BoxhostsPendingController = Em.ArrayController.extend
  errors: null

  actions:
    select: (boxhost) ->
      @transitionToRoute 'boxhost.setup', boxhost
