App.Part = Em.Object.extend
  name: null
  description: null
  version: null
  installed_version: null
  installed: false
  status: null
  category: null

  errorMessage: null

  humanized: (->
    # Conventional description format is `Name: Description`
    nameAndDescription = @get('description')
    if nameAndDescription && nameAndDescription.indexOf(':') > -1
      [ name, description ] = nameAndDescription.split(':')
    else
      # if a package doesn't follow the conventional format,
      # just use the given name and description.
      name = @get('name').replace(/[_-]/g, ' ').capitalize()
      description = nameAndDescription

    name: name?.trim()
    description: description?.trim()
  ).property 'description', 'name'

  running: (->
    @get('status') == 'running'
  ).property 'status'

App.PartsCollection = Em.ArrayProxy.extend
  content: null

  setPropertyOn: (name, property, value) ->
    part = @get('content').find (p) ->
      p.get('name') == name
    return unless part
    part.set(property, value)

  categories: (->
    categories = Em.A([])
    @get('content').forEach (part) ->
      cname = part.get('category')
      return if !cname

      if category = categories.findBy 'name', cname
        return category.get('parts').pushObject part

      parts = Em.A([part])
      categories.pushObject Em.Object.create(name: cname, parts: parts)

    return categories
  ).property 'content'

App.PartsCollection.reopenClass
  createWithModels: (parts) ->
    models = _.map parts, (attrs) ->
      App.Part.create attrs
    App.PartsCollection.create content: Em.A(models)
