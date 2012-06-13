aio.views.console ||= {}
aio.views.console.boxes ||= {}

class aio.views.console.boxes.NewView extends Backbone.View
  template: JST['previous/templates/console/boxes/new_view']
  id: 'console-boxes-new'
  className: 'console-content'

  initialize: ->
    @collection.on('reset add remove', this.render, this)
    @model = new @collection.model

  render: ->
    @$el.html(this.template(box_templates: aio.app.boxTemplates.toJSON(), regions: aio.app.regions.toJSON()))
    this.$('form').backboneLink(@model)
    this.$('form :input').change()
    this.$('#customize_form').hide()
    this

  events:
    'click .submit': 'didClickCreateBoxButton'
    'click #customize_button': 'didClickCustomizeButton'

  didClickCreateBoxButton: (e) ->
    $button = $(e.target)
    $button.attr('disabled', true)
    aio.app.loadingIndicatorView.show()
    @collection.create @model.toJSON()
    , wait: true
    , success: (model, response) =>
        aio.app.loadingIndicatorView.hide()
        window.navigateTo("#boxes/#{model.id}")
    , error: (model, response) =>
        aio.app.loadingIndicatorView.hide()
        aio.helpers.AppHelper.handleErrorResponse(response, this.$('form'))
        $button.removeAttr('disabled')
    false

  didClickCustomizeButton: (e) ->
    this.$('#customize_form').toggle()
    false

