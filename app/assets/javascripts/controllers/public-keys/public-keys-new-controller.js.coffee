AIO.PublicKeysNewController = Em.ObjectController.extend
  save: ->
    record = @get 'content'
    record.save().then ->
      AIO.util.mixpanelIncrement 'ssh_keys_creation_successful_count'
      AIO.get('router').transitionTo 'publicKeys.index'
    , (e) ->
      AIO.util.mixpanelIncrement 'ssh_keys_creation_failed_count'

  cancel: ->
    AIO.get('router').transitionTo 'publicKeys.index'
