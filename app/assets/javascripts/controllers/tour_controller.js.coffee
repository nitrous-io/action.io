AIO.TourController = Em.Controller.extend
  tour: null
  step: null
  sign_in_limit: 5 # tour is shown only if sign in count is below this value

  initialize: (tour) ->
    sign_in_limit = @get 'sign_in_limit'
    currentUser = AIO.get 'router.applicationController.currentUser'
    sign_in_count = currentUser.get 'sign_in_count'
    if sign_in_count < sign_in_limit && !currentUser.shouldHideTour(tour)
      Em.run.next =>
        this.start()

  reset: ->
    @set 'step', null
    @set 'tour', null

  start: ->
    @set 'step', 0

  nextStep: ->
    Em.run.scheduleOnce 'afterRender', this, ->
      if @get('step')?
        @incrementProperty 'step'

  close: ->
    @set 'step', null
    if currentUser = AIO.get 'router.applicationController.currentUser'
      currentUser.hideTour @get('tour')
