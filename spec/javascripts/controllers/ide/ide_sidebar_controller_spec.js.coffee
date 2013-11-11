describe 'AIO.IdeSidebarController', ->
  controller = null
  sftpSocket = null

  createPath = (attributes) ->
    path = AIO.Path.create attributes
    controller.get('rootPath').addObject path
    path

  stubSftpSocket = ->
    sftpSocket = {
      rename: ->
      fetchFileList: ->
    }
    sinon.stub sftpSocket, 'rename'
    sinon.stub sftpSocket, 'fetchFileList'
    sftpSocket

  beforeEach ->
    sftpSocket = stubSftpSocket()
    controller = AIO.get('router.ideSidebarController')
    controller.reset()
    controller.initialize()
    controller.set 'sftpSocketReady', true
    controller.set 'sftpSocket', sftpSocket

  describe '#openPath', ->
    it 'does not open the path when it is being loaded', ->
      sinon.spy(controller, 'fetchFileContent')
      path = createPath absolutePath: 'hello.txt'
      path.incrementProperty 'loadCount'
      Em.run -> controller.openPath path
      expect(controller.fetchFileContent).to.not.have.been.called

  describe '#downloadPath', ->
    path = null
    sftpSocket = null

    beforeEach ->
      sftpSocket = {
        downloadFile: ->
      }
      sinon.stub(sftpSocket, 'downloadFile')
      controller.set 'sftpSocket', sftpSocket
      path = createPath absolutePath: 'hello.txt'

    doAction = ->
      Em.run -> controller.downloadPath path

    it 'does not download the path when it is being loaded', ->
      path.incrementProperty 'loadCount'
      doAction()
      expect(sftpSocket.downloadFile).to.not.have.been.called

    it 'does not download if the path is a directory', ->
      path.set 'directory', true
      doAction()
      expect(sftpSocket.downloadFile).to.not.have.been.called

    it 'calls download with the absolute path of the file', ->
      doAction()
      expect(sftpSocket.downloadFile).to.have.been.calledWith 'hello.txt', sinon.match.func

    context 'when theres an error in downloading the file', ->
      beforeEach ->
        sinon.spy AIO, 'set'
        doAction()

      afterEach ->
        AIO.set.restore()

      it 'show a generic error message for other errors', ->
        sftpSocket.downloadFile.yield 'aio:some_error'
        expect(AIO.set).to.have.been.calledWith 'flashMessage', { type: 'error', text: "Cannot download the selected file." }

  describe '#delete', ->
    path = null

    beforeEach ->
      sftpSocket = {
        deleteFile: ->
        deleteDir: ->
      }
      sinon.stub sftpSocket, 'deleteFile'
      sinon.stub sftpSocket, 'deleteDir'
      controller.set 'sftpSocket', sftpSocket
      path = createPath absolutePath: 'hello.txt', directory: true

    doAction = ->
      Em.run -> controller.delete path

    context 'when a path given is the root path in sidebar', ->
      beforeEach ->
        controller.set 'rootPath', path

      it 'does nothing', ->
        doAction()
        expect(path.get 'loadCount').to.equal 0
        expect(path.get 'beingDeleted').to.be.false
        expect(sftpSocket.deleteFile).not.to.have.been.called
        expect(sftpSocket.deleteDir).not.to.have.been.called

    it 'increments loadCount of the path', ->
      doAction()
      expect(path.get('loadCount')).to.equal 1

    it 'sets beingDeleted property to be true', ->
      doAction()
      expect(path.get 'beingDeleted').to.be.true

    context 'when deleting a directory', ->
      it 'request the server to delete the path', ->
        path.set 'directory', true
        doAction()
        expect(sftpSocket.deleteDir).to.have.been.calledWith 'hello.txt', sinon.match.func

    context 'when deleting a file', ->
      it 'request the server to delete the path', ->
        path.set 'directory', false
        doAction()
        expect(sftpSocket.deleteFile).to.have.been.calledWith 'hello.txt', sinon.match.func

    context 'when deletion is successful', ->
      beforeEach ->
        sftpSocket.deleteDir.callsArgWith 1, undefined
        doAction()

      it 'sets the deleted property to be true', ->
        expect(path.get 'deleted').to.be.true

      it 'removes the path', ->
        expect(controller.get('rootPath.content')).to.not.include(path)
        expect(controller.get('content')).to.not.include(path)

    context 'when the deletion fails', ->
      beforeEach -> sftpSocket.deleteDir.callsArgWith 1, 'error'

      it 'decrements the loadCount', ->
        doAction()
        expect(path.get('loadCount')).to.equal 0

      it 'sets the beingDeleted property back to false', ->
        doAction()
        expect(path.get 'beingDeleted').to.be.false
        expect(controller.get 'rootPath.content').to.include path
        expect(controller.get 'content').to.include path

  describe '#newPath', ->
    path = null

    before ->
      sinon.stub controller, 'openPath'

    beforeEach ->
      path = createPath absolutePath: '/home/user/project'

    context 'called on a collapsed path', ->
      it 'opens the path', ->
        path.set 'expanded', false
        Em.run -> controller.newPath path
        expect(controller.openPath).to.have.been.calledWith path

    context 'adding a new directory', ->
      it 'adds a new path under the given path', ->
        Em.run -> controller.newPath path, true
        expect(path.content[path.content.length - 1].directory).to.equal true

    context 'adding a new file', ->
      it 'adds a new path under the given path', ->
        Em.run -> controller.newPath path, false
        expect(path.content[path.content.length - 1].directory).to.equal false

  describe '#saveNewPath', ->
    path = null
    parentPath = null

    beforeEach ->
      sftpSocket = {
        makeDirectory: ->
        writeNewFile: ->
      }
      sinon.stub sftpSocket, 'makeDirectory'
      sinon.stub sftpSocket, 'writeNewFile'
      controller.set 'sftpSocket', sftpSocket

      path = createPath absolutePath: '/home/user/__aio_untitled_path__'

      homePath = {
        findByRelativePath: ->
      }
      parentPath = createPath absolutePath: '/home/user/', directory: true
      sinon.stub(homePath, 'findByRelativePath').returns parentPath
      controller.set 'homePath', homePath

    context 'path is a directory', ->
      it 'request the server to create a new directory', ->
        path.set 'directory', true
        Em.run -> controller.saveNewPath path, 'new-dir'
        expect(sftpSocket.makeDirectory).to.have.been.calledWith '/home/user/new-dir', sinon.match.func

    context 'path is a file', ->
      it 'request the server to create a new file', ->
        path.set 'directory', false
        Em.run -> controller.saveNewPath path, 'new-file.txt'
        expect(sftpSocket.writeNewFile).to.have.been.calledWith '/home/user/new-file.txt', '', sinon.match.func

    context 'when new path operation completes', ->
      beforeEach ->
        sinon.stub controller, 'refresh'

      afterEach ->
        controller.refresh.restore()

      it 'remove the new flag from path', ->
        sftpSocket.writeNewFile.callsArgWith 2, undefined
        Em.run -> controller.saveNewPath path, 'new-file.txt'
        expect(path.get('new')).to.be.false

      it 'calls refresh on parent path', ->
        sftpSocket.writeNewFile.callsArgWith 2, undefined
        Em.run -> controller.saveNewPath path, 'new-file.txt'
        expect(controller.refresh).to.have.been.calledWith parentPath

  describe '#cancelNewPath', ->
    path = null
    parentPath = null

    beforeEach ->
      path = createPath absolutePath: '/home/user/__aio_untitled_path__'

      parentPath = createPath absolutePath: '/home/user/', directory: true
      parentPath.get('content').addObject path

      homePath = { findByRelativePath: -> }
      sinon.stub(homePath, 'findByRelativePath').returns parentPath

      controller.set 'homePath', homePath

    it 'remove path object from its parent', ->
      expect(parentPath.get 'content').to.include path
      Em.run -> controller.cancelNewPath path
      expect(parentPath.get 'content').not.to.include path

  describe '#renamePath', ->
    it 'makes the path editable', ->
      path = createPath absolutePath: 'hello.txt'
      Em.run -> controller.renamePath path
      expect(path.get 'editable').to.be.true

  describe '#applyRenamedPath', ->
    path = null
    homePath = null

    beforeEach ->
      homePath = createPath absolutePath: '', directory: true, expanded: true
      controller.set 'homePath', homePath
      controller.setHomeAsRoot()
      path = createPath absolutePath: 'hello.txt', editable: true

    doAction = (name='hello-2.txt')->
      Em.run -> controller.applyRenamedPath path, name

    it 'resets the renamed path when path is not modified', ->
      doAction('hello.txt')
      expect(path.get('editable')).to.be.false
      expect(path.get('loadCount')).to.eq 0

    it 'increments loadCount of the path', ->
      doAction()
      expect(path.get('loadCount')).to.equal 1

    it 'request the server to rename the path', ->
      doAction()
      expect(sftpSocket.rename).to.have.been.calledWith 'hello.txt', 'hello-2.txt', sinon.match.func

    context 'when the rename is successful', ->
      beforeEach ->
        doAction()
        sftpSocket.rename.yield(null)

      it 'decrements the loadCount of the path', ->
        expect(path.get 'loadCount').to.equal 0

      it 'calls refresh on parent path', ->
        expect(sftpSocket.fetchFileList).to.have.been.calledWith '', sinon.match.func

      it 'sets editable to be false', ->
        expect(path.get 'editable').to.be.false

      it 'sets the absolutePath to new file path', ->
        expect(path.get 'absolutePath').to.equal 'hello-2.txt'

    context 'when an error occurs', ->
      beforeEach ->
        doAction()
        sftpSocket.rename.yield 'Error: Couldn\'t rename file "/home/action/loloh" to "/home/action/lololol": Failure'

      afterEach ->

      it 'decrements the loadCount of the path', ->
        expect(path.get 'loadCount').to.equal 0

      it 'sets editable to be false', ->
        expect(path.get 'editable').to.be.false

      it 'calls refresh on parent path', ->
        expect(sftpSocket.fetchFileList).to.have.been.calledWith '', sinon.match.func

      it 'shows error dialog', ->
        expect(AIO.get 'flashMessage').not.to.be.null

  describe '#resetRenamedPath', ->
    it 'switch off the edit mode', ->
      path = createPath absolutePath: 'hello.txt'
      Em.run -> controller.resetRenamedPath path
      expect(path.get 'editable').to.be.false

  describe '#moveDraggedPathTo', ->
    currentlyDraggedPath = null
    droppablePath = null
    homePath = null

    beforeEach ->
      homePath = createPath absolutePath: '', directory: true, expanded: true
      controller.set 'homePath', homePath
      controller.setHomeAsRoot()

      currentlyDraggedPath = createPath absolutePath: 'hello.txt'
      droppablePath = createPath absolutePath: 'other', directory: true, expanded: true
      controller.set 'currentlyDraggedPath', currentlyDraggedPath

    doAction = ->
      Em.run -> controller.moveDraggedPathTo droppablePath

    it 'moves the dragged path to the given path', ->
      doAction()
      expect(sftpSocket.rename).to.have.been.calledWith 'hello.txt', 'other/hello.txt', sinon.match.func

    it 'refreshes the given path after the move', ->
      doAction()
      Em.run -> sftpSocket.rename.yield(null)
      expect(sftpSocket.fetchFileList).to.have.been.calledWith '', sinon.match.func
      expect(sftpSocket.fetchFileList).to.have.been.calledWith 'other', sinon.match.func

    it 'resets the currentlyDraggedPath', ->
      doAction()
      expect(controller.get('currentlyDraggedPath')).to.be.null

    it 'resets the currentDroppable', ->
      doAction()
      expect(controller.get('currentDroppable')).to.be.null
