AIO.BoxesEditResourcesController = Em.ObjectController.extend
  save: (changes) ->
    record = @get 'content'
    record.set 'saving', true
    record.set 'memoryChanged', changes['memory'] == true
    record.set 'storageChanged', changes['storage'] == true
    record.saveResource()
      .fail (e) ->
        if e.status == 422
          record.set 'errors', $.parseJSON(e.responseText).errors
      .done ->
        AIO.get('router').transitionTo 'boxes.index', record
      .always ->
        record.set 'saving', false

  cancel: ->
    record = @get 'content'
    record.set 'memoryChanged', false
    record.set 'storageChanged', false
    AIO.get('router').transitionTo 'boxes.index'
