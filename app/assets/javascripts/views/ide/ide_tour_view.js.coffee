AIO.IdeTourView = Em.View.extend
  templateName: 'templates/ide/tour'
  elementId: 'ide_tour_view'
  classNames: ['hidden']

  steps: [
    {
      target: '#ide_main_menu_view'
      content: 'Welcome to the Web IDE for your box. Simple keyboard shortcuts are listed to the right of each menu item.'
      placement: 'bottom'
    },
    {
      target: '#ide_sidebar_view'
      content: 'This is the file directory browser for your box. You can browse the file system, create and remote files, etc...'
      placement: 'right'
    },
    {
      target: '#ide_console_view'
      content: "This is a full linux shell for your box. Try typing any regular linux command and you'll see you can work with your box directly from the command line! Click the icon on the far right of the console to expand to fullscreen."
      placement: 'top'
    }
  ]

  didInsertElement: ->
    this._initPopovers()

  _initPopovers: ->
    _.each @get('steps'), (step) =>
      $(step.target).popover
        content: =>
          @$().find('.content').html(step.content)
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
