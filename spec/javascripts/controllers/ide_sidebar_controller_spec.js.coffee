#= require spec_helper

describe 'AIO.IdeSidebarController', ->
  controller = null

  beforeEach -> controller = AIO.get("router.ideSidebarController")

  describe '#openPath', ->
    it "does not open the path when it is marked as deleted", ->
      path = AIO.Path.create deleted: true, loading: false
      controller.set 'sftpSocketReady', true
      sinon.spy(controller, "fetchFileContent")
      sinon.spy(controller, "fetchFileList")
      Em.run -> controller.openPath path
      expect(controller.fetchFileContent).to.not.have.been.called
      expect(controller.fetchFileContent).to.not.have.been.called


  describe '#delete', ->
    sftpSocket = parentPath = homePath = path = null

    beforeEach ->
      sftpSocket = { delete: -> }
      homePath   = AIO.Path.create()
      parentPath = AIO.Path.create()
      path = AIO.Path.create()
      parentPath.addObject path

      controller.set 'homePath', homePath
      controller.set 'sftpSocket', sftpSocket
      sinon.stub sftpSocket, "delete"
      sinon.stub(homePath, "findByRelativePath").returns parentPath

    it 'request the server to delete the path', ->
      sinon.stub(path, "get").withArgs("absolutePath").returns "absolute_path"
      Em.run -> controller.delete path
      expect(sftpSocket.delete).to.have.been.calledWith "absolute_path", sinon.match.func

    it 'removes the path when delete success', ->
      sinon.stub(path, "get").withArgs("parentAbsolutePath").returns "absolute/path"
      homePath.findByRelativePath.withArgs("absolute/path").returns parentPath
      sftpSocket.delete.callsArgWith 1, undefined
      Em.run -> controller.delete path
      expect(parentPath.get('content')).to.not.include(path)

    it 'changes the path to not deleted back when the delete fails', ->
      sftpSocket.delete.callsArgWith 1, "error"
      Em.run -> controller.delete path
      expect(path.get("deleted")).to.be.false
      expect(parentPath.get('content')).to.include(path)

