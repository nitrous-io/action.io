class aio.models.File extends Backbone.Model
  defaults:
    open: false

  initialize: ->
    this.set('directory', this.get('path').substr(-1, 1) == '/')

  parseList: (fileList=[]) ->
    if this.get('directory')
      children = new aio.collections.Files
      for fileName in fileList
        name = if fileName.substr(-1, 1) == '/' then fileName.slice(0, -1) else fileName
        children.add(new aio.models.File(name: name, path: this.get('path') + fileName))
      this.set(children: children)

  findFile: (path) ->
    path = path.substring(1) if path[0] == '/'
    path = path.slice(0, -1) if path.substr(-1, 1) == '/'
    path = path.split('/')
    console.log path
    return this if path[0].length == 0
    file = this
    for name in path
      file = file.get('children').where(name: name)[0]
      break unless file
    file

class aio.collections.Files extends Backbone.Collection
  model: aio.models.File

  comparator: (model) ->
    model.get('name').toLowerCase()

