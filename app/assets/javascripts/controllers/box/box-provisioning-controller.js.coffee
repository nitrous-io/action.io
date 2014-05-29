App.BoxProvisioningController = Em.ObjectController.extend
  redirectBasedOnState: (->
    if model = @get 'model'
      if model.get('state') == 'running'
        Em.run.next =>
          if model.get('last_added_repository_id')
            @transitionToRoute 'box.ide', model, queryParams: { repository_id: model.get('last_added_repository_id') }
          else
            @transitionToRoute 'box.ide', model
      else if model.get('state') == 'failed'
        Em.run.next =>
          @transitionToRoute 'boxes.index'
          App.set 'flashMessage', { type: 'error', text: 'Sorry, there seems to be a problem creating your box. Please try again later or in a different region.' }
  ).observes 'state'
