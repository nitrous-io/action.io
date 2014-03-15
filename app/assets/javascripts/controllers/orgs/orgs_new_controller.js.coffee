AIO.OrgsNewController = Em.ObjectController.extend
  newRecord: ->
    @set 'content', AIO.Org.create()

  save: ->
    record = @get 'content'
    record.set 'saving', true
    record.saveResource()
      .fail (e) ->
        console.log 'omg fail'
      .done ->
        console.log 'done'
      .always ->
        record.set 'saving', false

  cancel: ->
    AIO.get('router').transitionTo 'boxes.index'

