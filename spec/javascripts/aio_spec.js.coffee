describe 'aio.app', ->
  mockPusher = null

  doAction = (params={}) ->
    aio.app.initialize(_(environment: 'production').extend(params))

  context 'when pusherKey is given', ->
    before ->
      doAction(pusherKey: 'pusher-key-123')

    it 'initializes @pusher', ->
      expect(aio.app.pusher instanceof Pusher).toBe true
      expect(aio.app.pusher.key).toEqual 'pusher-key-123'

  context 'when currentUser is given', ->
    currentUserJSON = null

    before ->
      currentUserJSON =
        currentUser:
          id: 1
          username: 'petejkim'
          email: 'pete@action.io'
          full_name: 'Pete Kim'
          authentications: [
            {
              id: 1
              provider: 'github'
              uid: '30173'
            }
          ]
      doAction(currentUser: currentUserJSON)

    it 'initializes @currentUser with User model', ->
      expect(aio.app.currentUser instanceof aio.models.User).toBe true
      expect(aio.app.currentUser.toJSON()).toEqual currentUserJSON

