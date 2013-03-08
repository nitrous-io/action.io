AIO.PublicKeysNewController = Em.ObjectController.extend
  publicKeys: null
  needs: ['publicKeysIndex']
  publicKeysBinding: 'controllers.publicKeysIndex'

  save: ->
    record = @get 'content'
    record.save =>
      @get('publicKeys').addObject record
      @transitionToRoute 'public_keys.index'

  cancel: ->
    @set 'content', null
    this.transitionToRoute 'public_keys.index'
