klass = AIO.Path = Em.ArrayProxy.extend Em.SortableMixin,
  sortProperties: ['persisted', 'lowerCaseName']
  expanded: false
  absolutePath: ''
  loadCount: 0
  directory: false
  size: 0
  editable: false
  new: false
  beingDeleted: false
  isRootPath: false

  init: ->
    @_super()
    @set 'content', [] unless @get 'content'

  persisted: (->
    !@get 'new'
  ).property 'new'

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

  parentAbsolutePath: (->
    if absolutePath = @get 'absolutePath'
      absolutePath.split('/').slice(0, -1).join '/'
  ).property 'absolutePath'

  findByRelativePath: (path) ->
    if _.isString path
      if path.length == 0 || path == '/'
        return this
      path = @constructor.pathToComponents(path)
    content = @get 'content'
    if found = content.findProperty 'name', path[0]
      found = found.findByRelativePath(path.slice 1) if path.length > 1
    found

  updateContent: (controller, newContent) ->
    absolutePath = @get 'absolutePath'
    content = @get 'content'

    allPaths = controller.get('content')
    existingContentNames = content.map (path) -> path.get 'name'

    refreshedContents = [] # content that we will replace `content` with
    refreshedContents = newContent.map (item) =>
      [name, isDir, size] = item
      path = if existingContentNames.contains name
        path = this.findByRelativePath name
        if !isDir && path.get 'directory'
          path.set 'content', []
        path
      else
        absolutePathForItem = _.chain([absolutePath, name]).compact().join('/').value()
        AIO.Path.create controller, absolutePath: absolutePathForItem
      path.setProperties
        directory: isDir
        size: size
      path

    refreshedNames = newContent.map (item) -> item[0]
    removedContents = [] # content that we will removed from controller#content
    removedContents = @get('content').reject (path) ->
      refreshedNames.contains(path.get('name'))

    controller.removeObjects removedContents
    this.set 'content', refreshedContents

klass.reopenClass
  _create: klass.create

  create: (controller, options) ->
    path = klass._create.apply this, [options]
    unless path.get 'new'
      allPaths = controller.get('content')
      if allPaths
        absolutePath = path.get 'absolutePath'
        if absolutePath && existingPath = allPaths.findProperty 'absolutePath', absolutePath
          return existingPath
        allPaths.pushObject path
    path

  pathToComponents: (pathString) ->
    pathString.split '/'
