class AIO.File extends AIO.Model
  initialize: ->
    @files = new Backbone.Collection()
    @files.model = AIO.File

  defaults:
    path: null # ~/ is prepended by server
    root: false

  parseAndAddFileList: (fileList) ->
    currentFileList = (file.get('path') for file in @files.models)
    newFileList = (this.get('path') + fileName for fileName in fileList)
    addedFileList = _.difference(newFileList, currentFileList)
    removedFileList = _.difference(currentFileList, newFileList)

    for path in addedFileList
      unless file = AIO.c.files.where(path: path)[0]
        file = new AIO.File(path: path)
      @files.add(file)

    for path in removedFileList
      @files.remove(@files.where(path: path))
      AIO.c.files.remove(AIO.c.files.where(path: path))

  cleanUp: ->
    for file in @files.models
      file.cleanUp()
    @files.aio_removeAll()

  save: (content) ->
    AIO.events.emit('writeFile', this.get('path'), this.cid, content)

AIO.File.setup('files')

