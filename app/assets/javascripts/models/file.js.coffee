class AIO.File extends AIO.Model
  constructor: (attributes={}) ->
    @socket = attributes.socket
    delete attributes.socket
    super(attributes)

  initialize: ->
    @files = new Backbone.Collection()
    @files.model = AIO.File

  defaults:
    path: '' # ~/ is prepended by server
    root: false
    loading: false

  fetchFileList: ->
    this.set(loading: true)
    @socket.emit('list', this.get('path'), @cid)

  parseAndAddFileList: (fileList) ->
    currentFileList = (file.get('path') for file in @files.models)
    newFileList = (this.get('path') + fileName for fileName in fileList)
    addedFileList = _.difference(newFileList, currentFileList)
    removedFileList = _.difference(currentFileList, newFileList)

    for path in addedFileList
      @files.add(new AIO.File(path: path, socket: @socket))

    for path in removedFileList
      @files.remove(@files.where(path: path))
      AIO.c.files.remove(AIO.c.files.where(path: path))

    this.set(loading: false)

AIO.File.setup('files')

