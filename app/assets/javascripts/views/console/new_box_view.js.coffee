aio.views ||= {}
aio.views.console ||= {}

class aio.views.console.NewBoxView extends Backbone.View
  template: JST['console/new_box']
  id: 'console-new_box'
  className: 'console-content'

  initialize: ->
    aio.app.collections.boxTemplates.on('reset add remove', this.render, this)
    @model = new aio.models.Box

  render: ->
    @$el.html(this.template(box_templates: aio.app.collections.boxTemplates.toJSON()))
    this.$('form').backboneLink(@model)
    this

  events:
    'click #create_box_button': 'didClickCreateBoxButton'

  didClickCreateBoxButton: (e) ->
    $button = $(e.target)
    $button.attr('disabled', true).text('Creating...')
    this.$('form :input').change()
    @model.save null, success: (model, response) ->
      aio.app.collections.boxes.add(model)  
      window.navigateTo('#')
    false
