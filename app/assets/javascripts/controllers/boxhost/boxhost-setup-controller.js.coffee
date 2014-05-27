App.BoxhostSetupController = Em.ObjectController.extend
  errors: null

  actions:
    save: (boxhost) ->
      self = this
      boxhost.save().then ->
        boxhost.provision().then ->
          self.transitionTo 'boxhost.provisioning', boxhost
        , ->
          if !boxhost.get('errors')
            boxhost.set('errors', base: ['An unexpected error has occurred
              during setup. Please try again or contact support@nitrous.io.'])
