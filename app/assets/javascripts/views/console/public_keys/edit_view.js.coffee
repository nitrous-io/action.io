aio.views.console ||= {}
aio.views.console.public_keys ||= {}

class aio.views.console.public_keys.EditView extends Backbone.View
  template: JST['console/public_keys/edit_view']
  id: 'console-public_keys-edit'
  className: 'console-content'

  render: ->
    @$el.html(this.template(@model.toJSON()))
    this.$('form').backboneLink(@model)
    this.$('form :input').change()
    this

  events:
    'click .submit': 'didClickSaveButton'

  didClickSaveButton: (e) ->
    $button = $(e.target)
    $button.attr('disabled', true)
    aio.app.loadingIndicatorView.show()
    @model.save null
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

