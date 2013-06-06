AIO.TourController = Em.Controller.extend
  tour: null
  step: null
  sign_in_limit: 500 # tour is shown only if sign in count is below this value

  initialize: (tour) ->
    @set 'tour', tour

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
