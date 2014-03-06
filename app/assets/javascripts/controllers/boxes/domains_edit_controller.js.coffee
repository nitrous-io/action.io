AIO.DomainsEditController = Em.ObjectController.extend
  boxCustomDomainPlaceholder: 'www.example.com'

  save: ->
    record = @get 'content'
    record.updateCustomDomain (err) ->
      return if err
      AIO.get('router').transitionTo 'boxes.index'
      Em.run.next ->
        if record.custom_domain?
          AIO.set 'flashMessage', { type: 'alert-info', text: 'Your box will shortly be accessible for preview at the new domain.' }
        else
          AIO.set 'flashMessage', { type: 'alert-info', text: 'Custom domain for this box has been removed' }

  cancel: ->
    AIO.get('router').transitionTo 'boxes.index'
