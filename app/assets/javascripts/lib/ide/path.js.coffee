klass = AIO.Path = Em.ArrayProxy.extend Em.SortableMixin,
  sortProperties: ['lowerCaseName']
  expanded: false
  absolutePath: ''
  loadCount: 0
  directory: false
  size: 0

  init: ->
    @_super()
    @set 'content', [] unless @get 'content'

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

  hidden: (->
    if name = @get 'name'
      name[0] == '.'
  ).property 'name'

  file: (->
    !@get 'directory'
  ).property 'directory'

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
    existingContentNames = content.map (path) -> path.get 'name'

    addedContent = []
    removedContent = []

    newContent.forEach (item) =>
      name = item[0]
      isDir = item[1]
      size = item[2]
      if existingContentNames.contains name
        path = this.findByRelativePath name
        if !isDir && path.get 'directory'
          path.set 'content', []
      else
        absolutePathForItem = _.chain([absolutePath, name]).compact().join('/').value()
        path = allPaths.findProperty('absolutePath', absolutePathForItem) || AIO.Path.createAndAddToAllPaths(absolutePath: absolutePathForItem)
        addedContent.push path
      path.setProperties
        directory: isDir
        size: size

    newContentNames = newContent.map (item) -> item[0]
    content.forEach (path) ->
      name = path.get 'name'
      unless newContentNames.contains name
        removedContent.push path

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
    pathString.split '/'

