klass = AIO.Path = Em.ArrayProxy.extend Em.SortableMixin,
  sortProperties: ['lowerCaseName']
  expanded: false
  absolutePath: ''
  loadCount: 0

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

  loading: (->
    @get('loadCount') > 0
  ).property 'loadCount'

  findByRelativePath: (path) ->
    if _.isString path
      if path.length == 0 || path == '/'
        return this
      path = @constructor.pathToComponents(path)
    content = @get 'content'
    found = content.findProperty 'name', path[0]
    found = found.findByRelativePath(path.slice 1) if path.length > 1
    found

  updateContent: (newContent) ->
    absolutePath = @get 'absolutePath'
    content = @get 'content'

    allPaths = AIO.get 'router.ideSidebarController.content'
    existingContent = content.map (path) -> path.get 'displayName'

    addedContent = _.chain(newContent).difference(existingContent).map((pathName) ->
      absolutePathForThis = absolutePath + pathName
      allPaths.findProperty('absolutePath', absolutePathForThis) || AIO.Path.createAndAddToAllPaths(absolutePath: absolutePathForThis)
    ).value()
    removedContent = _.chain(existingContent).difference(newContent).map((pathName) ->
      content.findProperty 'displayName', pathName
    ).value()

    allPaths.removeObjects removedContent
    this.addObjects addedContent
    this.removeObjects removedContent

AIO.Path.reopenClass
  createAndAddToAllPaths: (attrs) ->
    path = klass.create(attrs)
    if allPaths = AIO.get 'router.ideSidebarController.content'
      allPaths.pushObject path
    path

  pathToComponents: (pathString) ->
    if pathString.substr(-1) == '/'
      pathString = pathString.substr 0, pathString.length - 1
    pathString.split '/'

