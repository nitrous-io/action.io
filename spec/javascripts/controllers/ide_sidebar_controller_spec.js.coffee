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
    it "does not open the path when it is marked as deleted", ->
      sinon.spy(controller, "fetchFileContent")
      path = createPath absolutePath: "hello.txt", deleted: true, loading: false
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

    context 'when deleting a directory', ->
      it 'request the server to delete the path', ->
        path.set "directory", true
        Em.run -> controller.delete path
        expect(sftpSocket.deleteDir).to.have.been.calledWith "hello.txt", sinon.match.func

    context 'when deleting a file', ->
      it 'request the server to delete the path', ->
        path.set "directory", false
        Em.run -> controller.delete path
        expect(sftpSocket.deleteFile).to.have.been.calledWith "hello.txt", sinon.match.func

    it 'removes the path when delete success', ->
      sftpSocket.deleteDir.callsArgWith 1, undefined
      Em.run -> controller.delete path
      expect(controller.get('rootPath.content')).to.not.include(path)
      expect(controller.get('content')).to.not.include(path)

    it 'changes the path to not deleted back when the delete fails', ->
      sftpSocket.deleteDir.callsArgWith 1, "error"
      Em.run -> controller.delete path
      expect(path.get("deleted")).to.be.false
      expect(controller.get('rootPath.content')).to.include(path)
      expect(controller.get('content')).to.include(path)

