AIO.Part = Em.Object.extend
  name: null
  description: null
  version: null
  installed_version: null
  installed: false
  status: null

  errorMessage: null
  processing: false

  humanized: (->
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

  setPropertyOn: (name, property, value) ->
    part = @get('content').find (p) ->
      p.get('name') == name
    return unless part
    part.set(property, value)

AIO.PartsCollection.reopenClass
  createWithModels: (parts) ->
    models = _.map parts, (attrs) ->
      AIO.Part.create attrs
    AIO.PartsCollection.create content: Em.A(models)
