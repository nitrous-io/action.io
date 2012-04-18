describe 'aio.app', ->
  mockPusher = null

  before ->
    aio.app.initialize(environment: 'production', pusherKey: 'pusher-key-123')

  it 'initializes pusher', ->
    expect(aio.app.pusher instanceof Pusher).toBe true
    expect(aio.app.pusher.key).toEqual 'pusher-key-123'

