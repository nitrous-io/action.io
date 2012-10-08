#= require spec_helper

describe 'AIO.SftpSocket', ->
  sftpSocket = null

  beforeEach ->
    sftpSocket = AIO.SftpSocket.create()

  describe '#socketURI', ->
    context 'when box object with box_server_uri property exists', ->
      beforeEach ->
        sftpSocket.set 'box', Em.Object.create
          box_server_uri: 'example.com'

      it 'has the sftp websocket uri', ->
        expect(sftpSocket.get 'socketURI').to.equal 'example.com/ws/sftp'

    context 'when box object does not exist', ->
      it 'does not have a value', ->
        expect(sftpSocket.get 'socketURI').not.to.exist

