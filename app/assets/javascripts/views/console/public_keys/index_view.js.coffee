aio.views.console ||= {}
aio.views.console.public_keys ||= {}

class aio.views.console.public_keys.IndexView extends Backbone.View
  template: JST['console/public_keys/index_view']
  id: 'console-public_keys-index'
  className: 'console-content'

  initialize: ->
    @collection.on('reset add remove', this.render, this)

  render: ->
    @$el.html(this.template())
    for publicKey in @collection.models
      listItemView = new aio.views.console.public_keys.ListItemView(model: publicKey)
      this.$('ul').append(listItemView.render().$el)
    this

  events: ->
    'click #add_key_button' : 'didClickAddKeyButton'

  didClickAddKeyButton: ->
    window.navigateTo('#public_keys/new')

