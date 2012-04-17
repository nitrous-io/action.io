aio.views.console ||= {}
aio.views.console.boxes ||= {}

class aio.views.console.boxes.ShowView extends Backbone.View
  template: JST['console/boxes/show_view']
  id: 'console-boxes-show'
  className: 'console-content'

  initialize: ->
    @model.on('change', this.render, this)

  render: ->
    data = @model.toJSON()
    data.region = @model.region().toJSON()
    data.boxTemplate = @model.boxTemplate().toJSON()
    @$el.html(this.template(data))
    this

  events: ->
    'click #start_box_button'     : 'didClickStartBoxButton'
    #'click #terminate_box_button' : 'didClickTerminateBoxButton'
    'click #suspend_box_button'   : 'didClickSuspendBoxButton'
    'click #stop_box_button'      : 'didClickStopBoxButton'
    'click #resume_box_button'    : 'didClickResumeBoxButton'

  didClickStartBoxButton: ->
    aio.app.loadingIndicatorView.show()
    @model.start
      complete: ->
        aio.app.loadingIndicatorView.hide()

  didClickSuspendBoxButton: ->
    aio.app.loadingIndicatorView.show()
    @model.suspend
      complete: ->
        aio.app.loadingIndicatorView.hide()

  didClickStopBoxButton: ->
    aio.app.loadingIndicatorView.show()
    @model.stop
      complete: ->
        aio.app.loadingIndicatorView.hide()

  didClickResumeBoxButton: ->
    aio.app.loadingIndicatorView.show()
    @model.resume
      complete: ->
        aio.app.loadingIndicatorView.hide()


