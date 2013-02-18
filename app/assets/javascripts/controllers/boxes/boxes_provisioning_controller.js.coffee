AIO.BoxesProvisioningController = Em.ObjectController.extend
  redirectToIdeWhenRunning: (->
    if @get('content.isLoaded')
      content = @get('content')
      if content.get('state') == 'running'
        Em.run.next =>
          this.transitionToRoute 'ide', content
  ).observes 'content.state'
