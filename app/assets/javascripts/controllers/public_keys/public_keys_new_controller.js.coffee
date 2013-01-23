AIO.PublicKeysNewController = Em.ObjectController.extend
  newRecord: ->
    @set 'content', AIO.PublicKey.create()

  save: ->
    record = @get 'content'
    record.set 'saving', true
    record.saveResource()
      .fail (e) ->
        if e.status == 422
          AIO.util.mixpanelIncrement 'SSH Keys Creation Failed'
          record.set 'errors', $.parseJSON(e.responseText).errors
      .done ->
        AIO.util.mixpanelIncrement 'SSH Keys Creation Successful'
        AIO.get('router.publicKeysController').addObject record
        AIO.get('router').transitionTo 'publicKeys.index'
      .always ->
        record.set 'saving', false

  cancel: ->
    AIO.get('router').transitionTo 'publicKeys.index'

