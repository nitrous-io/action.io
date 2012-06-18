class AIO.BoxesProvisioningViewModel extends AIO.ViewModel
  constructor: (model) ->
    super(model)
    title = 'Your Box is Being Provisioned'
    titleCounter = 0
    @title = ko.observable(title)
    @titleInterval = window.setInterval =>
      @title(title + '...'.substring(0, (++titleCounter % 4)))
    , 1000
    @stateSub = @state.subscribe (state) =>
      if state == 'running'
        AIO.router.redirectTo "boxes/#{@id()}"

  __destroy: ->
    window.clearInterval(@titleInterval)
    delete @titleInterval
    @stateSub?.dispose()
    delete @stateSub
    super()

