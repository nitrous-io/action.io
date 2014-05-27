App.BoxhostSetupController = Em.ObjectController.extend
  errors: null

  actions:
    save: (boxhost) ->
      boxhost.save().then =>
        # TODO boxhost.provision()
        @transitionTo 'boxhost.provisioning', boxhost
