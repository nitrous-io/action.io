AIO.ResourcesEditController = Em.ObjectController.extend
  save: ->
    box = @get 'content'
    box.save().then =>
      Em.run.scheduleOnce 'afterRender', this, ->
        boxState = box.get('state')
        if boxState == 'stopped'
          AIO.set 'flashMessage', { type: 'alert-info', text: 'Changes will take place the next time your box is started' }
        else if boxState == 'running'
          AIO.set 'flashMessage', { type: 'alert-info', text: 'Your changes have been saved.  Your box should be updated in the next five minutes.' }

      AIO.get('router').transitionTo 'boxes.index'

  cancel: ->
    AIO.get('router').transitionTo 'boxes.index'
