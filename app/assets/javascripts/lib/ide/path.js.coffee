AIO.Path = Em.ArrayProxy.extend Em.SortableMixin,
  sortProperties: ['lowerCaseName']
  expanded: false
  absolutePath: ''

  init: ->
    @_super()
    @set 'content', [] unless @get 'content'

  directory: (->
    if absolutePath = @get 'absolutePath'
      absolutePath.substr(-1) == '/'
    else
      true
  ).property 'absolutePath'

  name: (->
    if absolutePath = @get 'absolutePath'
      components = @constructor.pathToComponents(absolutePath)
      components[components.length - 1]
    else
      '~'
  ).property 'absolutePath'

  lowerCaseName: (->
    if name = @get 'name'
      name.toLowerCase()
  ).property 'name'

  displayName: (->
    if name = @get 'name'
      name += '/' if directory = @get 'directory'
      name
  ).property 'name'

  findByRelativePath: (path) ->
    if _.isString path
      return this if path.length == 0
      path = @constructor.pathToComponents(path)
    content = @get 'content'
    found = content.findProperty 'name', path[0]
    found = found.findByRelativePath(path.slice 1) if path.length > 1
    found

  updateContent: (newContent) ->
    absolutePath = @get 'absolutePath'
    content = @get 'content'
    existingContent = content.map (path) -> path.get 'displayName'

    addedContent = _.chain(newContent).difference(existingContent).map((path) ->
      AIO.Path.create absolutePath: absolutePath + path
    ).value()
    removedContent = _.chain(existingContent).difference(newContent).map((path) ->
      content.findProperty 'displayName', path
    ).value()

    this.addObjects addedContent
    this.removeObjects removedContent

AIO.Path.reopenClass
  pathToComponents: (pathString) ->
    if pathString.substr(-1) == '/'
      pathString = pathString.substr(0, pathString.length - 1)
    pathString.split('/')

