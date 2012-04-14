aio.views.console ||= {}
aio.views.console.public_keys ||= {}

class aio.views.console.public_keys.NewView extends Backbone.View
  template: JST['console/public_keys/new_view']
  id: 'console-public_keys-new'
  className: 'console-content'

  initialize: ->
    @collection.on('reset add remove', this.render, this)
    @model = new @collection.model

  render: ->
    @$el.html(this.template())
    this.$('form').backboneLink(@model)
    this.$('form :input').change()
    this

  events:
    'click .submit': 'didClickAddKeyButton'

  didClickAddKeyButton: (e) ->
    $button = $(e.target)
    $button.attr('disabled', true)
    aio.app.loadingIndicatorView.show()
    @collection.create @model.toJSON()
    , wait: true
    , success: (model, response) =>
        @model = model
        aio.app.loadingIndicatorView.hide()
        window.navigateTo('#public_keys')
    , error: (model, response) =>
        aio.app.loadingIndicatorView.hide()
        aio.helpers.AppHelper.handleErrorResponse(response, this.$('form'))
        $button.removeAttr('disabled')
    false

