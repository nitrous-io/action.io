class AIO.File extends AIO.Model
  initialize: ->
    @files = new Backbone.Collection()
    @files.model = AIO.File

  defaults:
    path: '' # ~/ is prepended by server
    root: false
    socket: null

  fetchFileList: ->
    this.get('socket').socket.emit('list', this.get('path'), @cid)

  parseAndAddFileList: (fileList) ->
    currentFileList = _.map(@files.models, (file) -> file.get('path'))
    newFileList = _.map(fileList, (fileName) => this.get('path') + fileName)
    addedFileList = _.difference(newFileList, currentFileList)
    removedFileList = _.difference(currentFileList, newFileList)

    for path in addedFileList
      @files.add(new AIO.File(path: path, socket: this.get('socket')))
    for path in removedFileList
      @files.remove(@files.where(path: path))
      AIO.c.files.remove(AIO.c.files.where(path: path))

AIO.File.setup('files')

