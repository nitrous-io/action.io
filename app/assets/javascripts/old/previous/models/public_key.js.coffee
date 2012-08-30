class aio.models.PublicKey extends Backbone.Model

class aio.collections.PublicKeys extends Backbone.Collection
  model: aio.models.PublicKey
  url: '/public_keys'

  importGitHubKeys: (options={}) ->
    $.ajax
      type: 'POST'
      url: "#{this.url}/import_github_keys"
      success: (data) =>
        options.success(data) if options.success
      error: (data) =>
        options.error(data) if options.error
      complete: =>
        options.complete() if options.complete

