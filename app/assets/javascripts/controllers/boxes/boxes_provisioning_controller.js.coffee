AIO.BoxesProvisioningController = Em.ObjectController.extend
  needs: ['application']

  redirectBasedOnState: (->
    if content = @get 'content'
      if content.get('state') == 'running'
        Em.run.next =>
          @transitionToRoute 'ide', content
      if content.get('state') == 'failed'
        Em.run.next =>
          @transitionToRoute 'boxes.index'
          window.alert "Sorry, there seems to be a problem creating your box. Please try again later or in a different region."
  ).observes 'content.state'

