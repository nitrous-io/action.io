describe 'AIO.IdeSidebarController', ->
  controller = null
  sftpSocket = null

  createPath = (attributes) ->
    path = AIO.Path.create attributes
    controller.get('rootPath').addObject path
    path

  beforeEach ->
    controller = AIO.get('router.ideSidebarController')
    controller.reset()
    controller.initialize()
    controller.set 'sftpSocketReady', true

  describe '#openPath', ->
    it 'does not open the path when it is being loaded', ->
      sinon.spy(controller, 'fetchFileContent')
      path = createPath absolutePath: 'hello.txt'
      path.incrementProperty 'loadCount'
      Em.run -> controller.openPath path
      expect(controller.fetchFileContent).to.not.have.been.called

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
      it 'removes the path', ->
        sftpSocket.deleteDir.callsArgWith 1, undefined
        doAction()
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

      homePath = {
        findByRelativePath: ->
      }
      parentPath = createPath absolutePath: '/home/user/', directory: true
      sinon.stub(parentPath, 'removeObject')
      sinon.stub(homePath, 'findByRelativePath').returns parentPath
      controller.set 'homePath', homePath

    it 'remove path object from its parent', ->
      Em.run -> controller.cancelNewPath path
      expect(parentPath.removeObject).to.have.been.calledWith path

  describe '#renamePath', ->
    it 'makes the path editable', ->
      path = createPath absolutePath: 'hello.txt'
      Em.run -> controller.renamePath path
      expect(path.get 'editable').to.be.true

  describe '#applyRenamedPath', ->
    path = null
    parentPath = null

    beforeEach ->
      sftpSocket = {
        rename: ->
      }
      sinon.stub sftpSocket, 'rename'
      controller.set 'sftpSocket', sftpSocket
      path = createPath absolutePath: '/home/user/hello.txt', editable: true

      homePath = {
        findByRelativePath: ->
      }
      parentPath = createPath absolutePath: '/home/user', directory: true
      sinon.stub(homePath, 'findByRelativePath').returns parentPath
      controller.set 'homePath', homePath

    doAction = ->
      Em.run -> controller.applyRenamedPath path, 'hello-2.txt'

    it 'increments loadCount of the path', ->
      doAction()
      expect(path.get('loadCount')).to.equal 1

    context 'when renaming a path', ->
      it 'request the server to rename the path', ->
        doAction()
        expect(sftpSocket.rename).to.have.been.calledWith '/home/user/hello.txt', '/home/user/hello-2.txt', sinon.match.func

    context 'when rename operation completes', ->

      beforeEach ->
        sinon.stub controller, 'refresh'

      afterEach ->
        controller.refresh.restore()

      it 'makes the path uneditable', ->
        sftpSocket.rename.callsArgWith 2, undefined
        doAction()
        expect(path.get('editable')).to.be.false

      it 'decrements the loadCount of the path', ->
        sftpSocket.rename.callsArgWith 2, undefined
        doAction()
        expect(path.get('loadCount')).to.equal 0

      it 'calls refresh on parent path', ->
        sftpSocket.rename.callsArgWith 2, undefined
        doAction()
        expect(controller.refresh).to.have.been.calledWith parentPath

  describe '#resetRenamedPath', ->
    it 'makes the path uneditable', ->
      path = createPath absolutePath: 'hello.txt'
      Em.run -> controller.resetRenamedPath path
      expect(path.get 'editable').to.be.false

