describe 'AIO.SftpSocket', ->
  sftpSocket = null

  beforeEach ->
    sftpSocket = AIO.SftpSocket.create()

  describe 'constructor', ->
    it 'initializes the variables', ->
      expect(sftpSocket.connection).to.equal null
      expect(sftpSocket.socket).to.equal null
      expect(sftpSocket.eventBuffer).to.equal []
      expect(sftpSocket.box).to.equal null
      expect(sftpSocket.connected).to.equal false
      expect(sftpSocket.connectedFirstTime).to.equal false
