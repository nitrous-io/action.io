aio.views.console ||= {}
aio.views.console.public_keys ||= {}

class aio.views.console.public_keys.IndexView extends Backbone.View
  template: JST['previous/templates/console/public_keys/index_view']
  id: 'console-public_keys-index'
  className: 'console-content'

  initialize: ->
    @collection.on('reset add remove', this.render, this)

  render: ->
    @$el.html(this.template(publicKeys: @collection.models, currentUser: aio.app.currentUser))
    for publicKey in @collection.models
      listItemView = new aio.views.console.public_keys.ListItemView(model: publicKey)
      this.$('ul').append(listItemView.render().$el)
    this

  events: ->
    'click #add_key_button'            : 'didClickAddKeyButton'
    'click #import_from_github_button' : 'didClickImportFromGitHubButton'

  didClickAddKeyButton: ->
    window.navigateTo('#public_keys/new')

  didClickImportFromGitHubButton: (e) ->
    $(e.target).attr('disabled', true).text('Importing...')
    aio.app.loadingIndicatorView.show()
    @collection.importGitHubKeys
      error: (data) ->
        window.alert("An error occurred:\n\n#{data}")
      complete: ->
        aio.app.loadingIndicatorView.hide()

