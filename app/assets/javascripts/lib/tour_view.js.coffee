AIO.TourView = Em.View.extend
  templateName: 'templates/partials/tour'
  elementId: 'tour_view'
  classNames: ['hide']

  steps: null

  didInsertElement: ->
    @_super()
    this._initPopovers()

  _initPopovers: ->
    _.each @get('steps'), (step) =>
      $(step.target).popover
        content: =>
          @$().find('.content').html step.content
          @$().html()
        placement: step.placement
        trigger: 'manual'
        html: true

  showCommonActions: ->
    @$().find('.actions').removeClass 'hide'
    @$().find('.last_action').addClass 'hide'

  showLastAction: ->
    @$().find('.actions').addClass 'hide'
    @$().find('.last_action').removeClass 'hide'

  stepDidChange: (->
    controller = @get 'controller'
    steps = @get 'steps'
    currentStepIndex = controller.get 'step'

    if currentStepIndex < steps.length - 1
      this.showCommonActions()
    else
      this.showLastAction()

    _.each steps, (step, index) =>
      if index == currentStepIndex
        $(step.target).popover 'show'
      else
        $(step.target).popover 'hide'
  ).observes 'controller.step'

  didClickNext: ->
    @get('controller').nextStep()

  didClickClose: ->
    @get('controller').close()
