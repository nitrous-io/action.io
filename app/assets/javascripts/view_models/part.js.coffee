AIO.Part = Em.Object.extend
  name: null
  description: null
  version: null
  installed_version: null
  installed: false
  status: null

  displayProps: (->
    if desc = @get('description')
      nameAndDescription = desc.split(':')
      name = nameAndDescription[0]
      description = nameAndDescription[1].trim()

    name: name
    description: description
  ).property 'description'

  running: (->
    @get('status') == 'running'
  ).property 'status'

AIO.PartsCollection = Em.ArrayProxy.extend
  content: null

  installed: (name) ->
    this.setPropertyOn name, 'installed', true

  uninstalled: (name) ->
    this.setPropertyOn name, 'installed', false
    this.setPropertyOn name, 'status', null

  started: (name) ->
    this.setPropertyOn name, 'status', 'running'

  stopped: (name) ->
    this.setPropertyOn name, 'status', 'stopped'

  setPropertyOn: (name, property, value) ->
    part = @get('content').find (p) ->
      p.get('name') == name
    part.set property, value

AIO.PartsCollection.reopenClass
  createWithModels: (parts) ->
    models = _.map parts, (attrs) ->
      AIO.Part.create attrs
    AIO.PartsCollection.create content: Em.A(models)
