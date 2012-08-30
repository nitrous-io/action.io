aio.views.console ||= {}
aio.views.console.public_keys ||= {}

class aio.views.console.public_keys.ListItemView extends Backbone.View
  template: JST['previous/templates/console/public_keys/list_item_view']
  tagName: 'li'

  initialize: ->
    @model.on('change', this.render, this)

  render: ->
    @$el.html(this.template(@model.toJSON()))
    this

  events: ->
    'click #delete_public_key_button' : 'didClickDeletePublicKeyButton'

  didClickDeletePublicKeyButton: ->
    if window.confirm('Delete this public key?')
      aio.app.loadingIndicatorView.show()
      @model.destroy
        wait: true
        success: (model, response) =>
          aio.app.loadingIndicatorView.hide()
        error: (model, response) =>
          aio.app.loadingIndicatorView.hide()
    false

