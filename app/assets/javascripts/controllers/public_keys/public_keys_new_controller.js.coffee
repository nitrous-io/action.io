AIO.PublicKeysNewController = Em.ObjectController.extend
  needs: ['publicKeys']

  newRecord: ->
    @set 'content', AIO.PublicKey.create()

  save: ->
    record = @get 'content'
    record.set 'saving', true
    record.saveResource()
      .fail (e) ->
        if e.status == 422
          AIO.util.mixpanelIncrement 'ssh_keys_creation_failed_count'
          record.set 'errors', $.parseJSON(e.responseText).errors
      .done =>
        AIO.util.mixpanelIncrement 'ssh_keys_creation_successful_count'
        @get('controllers.publicKeys').addObject record
        @transitionToRoute 'public_keys'
      .always ->
        record.set 'saving', false

  cancel: ->
    @transitionToRoute 'public_keys'
