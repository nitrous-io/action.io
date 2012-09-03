AIO.PublicKeyController = Em.ObjectController.extend
  newRecord: ->
    @set 'content', AIO.PublicKey.create()

  save: ->
    record = @get 'content'
    record.set 'saving', true
    record.saveResource()
      .fail (e) ->
        if e.status == 422
          record.set 'errors', $.parseJSON(e.responseText).errors
      .done ->
        AIO.get('router.publicKeysIndexController').pushObject(record)
        AIO.get('router').transitionTo 'publicKeys.index'
      .always ->
        record.set 'saving', false

  cancel: ->
    AIO.get('router').transitionTo 'publicKeys.index'

