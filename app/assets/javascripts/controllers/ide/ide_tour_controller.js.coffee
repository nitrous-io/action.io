AIO.IdeTourController = Em.ArrayController.extend
  step: null

  initialize: ->

  reset: ->
    @set 'step', null

  start: ->
    @set 'step', 0

  nextStep: ->
    @incrementProperty 'step'

  close: ->
    @set 'step', null
