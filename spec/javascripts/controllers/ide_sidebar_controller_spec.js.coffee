#= require spec_helper

describe 'AIO.IdeSidebarController', ->
  controller = null
  sftpSocket = null

  createPath = (attributes) ->
    path = AIO.Path.create attributes
    controller.get("rootPath").addObject path
    path

  beforeEach ->
    controller = AIO.get("router.ideSidebarController")
    controller.reset()
    controller.initialize()
    controller.set 'sftpSocketReady', true

  describe '#openPath', ->
    it "does not open the path when it is being loaded", ->
      sinon.spy(controller, "fetchFileContent")
      path = createPath absolutePath: "hello.txt"
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
      sinon.stub sftpSocket, "deleteFile"
      sinon.stub sftpSocket, "deleteDir"
      controller.set "sftpSocket", sftpSocket
      path = createPath absolutePath: "hello.txt", directory: true

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
      expect(path.get("loadCount")).to.equal 1

    it 'sets beingDeleted property to be true', ->
      doAction()
      expect(path.get 'beingDeleted').to.be.true

    context 'when deleting a directory', ->
      it 'request the server to delete the path', ->
        path.set "directory", true
        doAction()
        expect(sftpSocket.deleteDir).to.have.been.calledWith "hello.txt", sinon.match.func

    context 'when deleting a file', ->
      it 'request the server to delete the path', ->
        path.set "directory", false
        doAction()
        expect(sftpSocket.deleteFile).to.have.been.calledWith "hello.txt", sinon.match.func

    context 'when deletion is successful', ->
      it 'removes the path', ->
        sftpSocket.deleteDir.callsArgWith 1, undefined
        doAction()
        expect(controller.get('rootPath.content')).to.not.include(path)
        expect(controller.get('content')).to.not.include(path)

    context 'when the deletion fails', ->
      beforeEach -> sftpSocket.deleteDir.callsArgWith 1, "error"

      it 'decrements the loadCount', ->
        doAction()
        expect(path.get("loadCount")).to.equal 0

      it 'sets the beingDeleted property back to false', ->
        doAction()
        expect(path.get 'beingDeleted').to.be.false
        expect(controller.get 'rootPath.content').to.include path
        expect(controller.get 'content').to.include path

