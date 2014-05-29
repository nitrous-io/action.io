App.BoxhostProvisioningController = Em.ObjectController.extend
  redirectBasedOnState: (->
    if model = @get 'model'
      switch model.get('state')
        when 'running'
          Em.run.next =>
            # FIXME Transition to a better screen, like the new box page with this
            # boxhost pre-selected.
            @transitionToRoute 'boxes.index'
        when 'failed'
          model.set('errors', { base: ['An unexpected error has occurred
            during setup. Please try again or contact support@nitrous.io.'] })
          Em.run.next =>
            @transitionToRoute 'boxhost.setup', model
  ).observes 'state'
