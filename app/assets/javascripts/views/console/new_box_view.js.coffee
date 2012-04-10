aio.views ||= {}
aio.views.console ||= {}

class aio.views.console.NewBoxView extends Backbone.View
  template: JST['console/new_box']
  id: 'console-new_box'
  className: 'console-content'

  initialize: ->
    aio.app.boxTemplates.on('reset add remove', this.render, this)
    @model = new aio.models.Box

  render: ->
    @$el.html(this.template(box_templates: aio.app.boxTemplates.toJSON()))
    this.$('form').backboneLink(@model)
    this.$('form :input').change()
    this

  events:
    'click #create_box_button': 'didClickCreateBoxButton'

  didClickCreateBoxButton: (e) ->
    $button = $(e.target)
    $button.attr('disabled', true).text('Creating...')
    aio.app.loadingIndicatorView.show()
    @model.save null
    , success: (model, response) =>
        aio.app.boxes.add(model)
        aio.app.loadingIndicatorView.hide()
        $button.text('Created!').addClass('btn-success').removeClass('btn-primary')
        window.navigateTo('#')
    , error: (model, response) =>
        aio.app.loadingIndicatorView.hide()
        window.alert("#{response.status}\n#{response.responseText}")
        $button.text('Create Box')
        $button.removeAttr('disabled')
    false

