AIO.BoxController = Em.ObjectController.extend
  newRecord: ->
    @set 'content', AIO.Box.create()

  save: ->
    record = @get 'content'
    record.set 'saving', true
    record.saveResource()
      .fail (e) ->
        if e.status == 422
          record.set 'errors', $.parseJSON(e.responseText).errors
      .done ->
        AIO.get('router.boxesIndexController').pushObject(record)
        AIO.get('router').transitionTo 'boxes.index'
      .always ->
        record.set 'saving', false

  cancel: ->
    AIO.get('router').transitionTo 'boxes.index'


