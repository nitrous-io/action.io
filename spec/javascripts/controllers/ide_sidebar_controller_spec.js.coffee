#= require spec_helper

describe 'AIO.IdeSidebarController', ->
  controller = null

  beforeEach -> controller = AIO.get("router.ideSidebarController")

  describe '#delete', ->
    sftpSocket = parentPath = homePath = path = null

    beforeEach ->
      sftpSocket = { delete: -> }
      homePath   = { findByRelativePath: -> }
      parentPath = {
        removeObject: ->
        addObject: ->
      }
      path = { get: (attr) -> }

      controller.set 'homePath', homePath
      controller.set 'sftpSocket', sftpSocket

    it 'request the server to delete the path', ->
      sinon.stub sftpSocket, "delete"
      sinon.stub(path, "get").withArgs("absolutePath").returns "absolute_path"

      controller.delete path
      expect(sftpSocket.delete).to.have.been.calledWith "absolute_path", sinon.match.func

    it 'removes the path from sidebar', ->
      sinon.stub parentPath, "removeObject"
      sinon.stub(path, "get").withArgs("parentAbsolutePath").returns "absolute/path"
      sinon.stub(homePath, "findByRelativePath").withArgs("absolute/path").returns parentPath

      controller.delete path
      expect(parentPath.removeObject).to.have.been.calledWith path

    it 're-adds the path back when the delete fails', ->
      sinon.stub(homePath, "findByRelativePath").returns parentPath
      sinon.stub parentPath, "addObject"
      sinon.stub(sftpSocket, "delete").callsArgWith 1, "error"

      controller.delete path
      expect(parentPath.addObject).to.have.been.calledWith path
