AIO.BaseModel = klass = Em.Model.extend
  id: Em.attr()

  makeRequest: (action, method='GET', params) ->
    @constructor.adapter?.makeRequest? this, action, method, params

klass.reopenClass
  # adapter: AIO.OAuthRESTAdapter.create()
  camelizeKeys: false # too much work
