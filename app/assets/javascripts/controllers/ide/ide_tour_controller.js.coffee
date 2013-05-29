AIO.IdeTourController = Em.Controller.extend
  step: null

  initialize: ->
    sign_in_count = AIO.get 'router.applicationController.currentUser.sign_in_count'
    hide_ide_tour = AIO.get 'router.applicationController.currentUser.hide_ide_tour'
    if sign_in_count < 5 && !hide_ide_tour
      Em.run.next =>
        this.start()

  reset: ->
    @set 'step', null

  start: ->
    @set 'step', 0

  nextStep: ->
    @incrementProperty 'step'

  close: ->
    @set 'step', null
    currentUser = AIO.get 'router.applicationController.currentUser'
    currentUser.hideIdeTour()
