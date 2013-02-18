DS.JSONSerializer.reopen
  pluralize: (string) ->
    return 'boxes' if string == 'box'
    @_super(string)

AIO.Store = DS.Store.extend
  revision: 11
  adapter: DS.RESTAdapter.create()
