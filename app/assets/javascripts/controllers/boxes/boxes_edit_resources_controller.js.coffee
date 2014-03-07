AIO.BoxesEditResourcesController = Em.ObjectController.extend
  save: ->
    record = @get 'content'
    record.set 'saving', true
    record.saveResource()
      .fail (e) ->
        if e.status == 422
          record.set 'errors', $.parseJSON(e.responseText).errors
      .done ->
        Em.run.scheduleOnce 'afterRender', this, ->
          boxState = record.get('state')
          if boxState == 'stopped'
            AIO.set 'flashMessage', { type: 'alert-info', text: 'Changes will take place the next time your box is started' }
          else if boxState == 'running'
            AIO.set 'flashMessage', { type: 'alert-info', text: 'Your changes have been saved.  Your box should be updated in the next five minutes.' }

        AIO.get('router').transitionTo 'boxes.index'
      .always ->
        record.set 'saving', false

  cancel: ->
    AIO.get('router').transitionTo 'boxes.index'
