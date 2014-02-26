AIO.PartOutputStream = Em.ArrayProxy.extend
  content: []
  completed: false
  exitStatus: null
  onComplete: null

  reset: ->
    @set 'content', []
    @set 'completed', false

  _didCompleteSuccessfully: (->
    if @get('completed') && @get('exitStatus') == 0
      @get('onComplete')?()
  ).observes 'completed'
