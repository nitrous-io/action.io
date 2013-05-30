AIO.TourController = Em.Controller.extend
  tour: null
  step: null
  sign_in_limit: 500 # tour is shown only if sign in count is below this value

  initialize: (tour) ->
    sign_in_limit = @get 'sign_in_limit'
    currentUser = AIO.get 'router.applicationController.currentUser'
    sign_in_count = currentUser.get 'sign_in_count'
    if sign_in_count < sign_in_limit && !currentUser.shouldHideTour(tour)
      Em.run.next =>
        @set 'tour', tour
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
    tour = @get 'tour'
    currentUser = AIO.get 'router.applicationController.currentUser'
    if tour && currentUser
      currentUser.hideTour tour
