AIO.RESTAdapter = Em.RESTAdapter.extend
  makeRequest: (record, action, method='GET', params)  ->
    recordClass = record.constructor
    urlRoot = recordClass.url
    id = record.get(recordClass.primaryKey)
    url = @buildURL(recordClass, id).replace /\.json$/, "/#{action}.json"
    @ajax url, params, method
