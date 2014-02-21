AIO.PartOutputStream = Em.ArrayProxy.extend
  content: []
  completed: false
  onComplete: null

  reset: ->
    @set 'content', []
    @set 'completed', false

  _didComplete: (->
    if @get('completed')
      @get('onComplete')?()
  ).observes 'completed'
