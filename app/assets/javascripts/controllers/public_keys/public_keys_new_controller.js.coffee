AIO.PublicKeysNewController = Em.ObjectController.extend
  save: ->
    record = @get 'content'
    unless errors = record.validate()
      @get('store').commit()
      record.addObserver 'id', this, 'afterCreate'

  afterCreate: ->
    @get('content').removeObserver 'id', this, 'afterCreate'
    this.transitionToRoute 'public_keys.index'

  cancel: ->
    @get('content').deleteRecord()
    this.transitionToRoute 'public_keys.index'
