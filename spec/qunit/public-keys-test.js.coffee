server = null

module 'Public Keys',
  setup: ->
    server = sinon.fakeServer.create()
    Em.run -> App.reset()

  teardown: ->
    server.restore()

test 'index', ->
  server.respondWith 'GET', '/public_keys.json', [
    200
    { 'Content-Type': 'application/json; charset=utf-8' }
    '{"public_keys":[' +
      '{"id":1,"user_id":1,"name":"mac","md5_fingerprint":"00:11:22:33:44:55:66:77:88:99:aa:bb:cc:dd:ee:ff"},' +
      '{"id":2,"user_id":1,"name":"ubuntu","md5_fingerprint":"ff:ee:dd:cc:bb:aa:99:88:77:66:55:44:33:22:11:00"}' +
      ']}'
  ]

  visit '/public_keys'

  server.respond()

  andThen ->
    $listItems = find '.public_keys > li'
    equal $listItems.length, 2, 'shows 2 items'

    firstItem = $listItems.eq(0).text()
    notEqual firstItem.indexOf('mac'), -1, 'shows name of key'
    notEqual firstItem.indexOf('00:11:22:33:44:55:66:77:88:99:aa:bb:cc:dd:ee:ff'), -1, 'shows md5 fingerprint'
