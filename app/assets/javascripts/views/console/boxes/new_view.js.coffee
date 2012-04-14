aio.views.console ||= {}
aio.views.console.boxes ||= {}

class aio.views.console.boxes.NewView extends Backbone.View
  template: JST['console/boxes/new_view']
  id: 'console-boxes-new'
  className: 'console-content'

  initialize: ->
    @collection.on('reset add remove', this.render, this)
    @model = new @collection.model

  render: ->
    @$el.html(this.template(box_templates: aio.app.boxTemplates.toJSON(), regions: aio.app.regions))
    this.$('form').backboneLink(@model)
    this.$('form :input').change()
    this

  events:
    'click .submit': 'didClickCreateBoxButton'

  didClickCreateBoxButton: (e) ->
    $button = $(e.target)
    $button.attr('disabled', true)
    aio.app.loadingIndicatorView.show()
    @collection.create @model.toJSON()
    , wait: true
    , success: (model, response) =>
        @model = model
        aio.app.loadingIndicatorView.hide()
        window.navigateTo("#boxes/#{model.id}")
    , error: (model, response) =>
        aio.app.loadingIndicatorView.hide()
        aio.helpers.AppHelper.handleErrorResponse(response, this.$('form'))
        $button.removeAttr('disabled')
    false

