describe 'public_keys', ->
  router = null
  describe 'index', ->
    beforeEach ->
      server.respondWith 'GET', '/public_keys', [
        200
        { 'Content-Type': 'application/json; charset=utf-8' }
        '{"public_keys":[' +
          '{"id":1,"user_id":1,"name":"mac","md5_fingerprint":"00:11:22:33:44:55:66:77:88:99:aa:bb:cc:dd:ee:ff"},' +
          '{"id":2,"user_id":1,"name":"ubuntu","md5_fingerprint":"ff:ee:dd:cc:bb:aa:99:88:77:66:55:44:33:22:11:00"}' +
          ']}'
      ]
      Ember.run ->
        router = AIO.lookup('router:main')
        router.transitionTo 'public_keys.index'
        server.respond()

    it 'lists public keys', ->
      $listItems = $('.public_keys > li')
      expect($listItems).to.have.length 2
      $firstItem = $listItems.eq(0).text()
      expect($firstItem).to.contain 'mac'
      expect($firstItem).to.contain '00:11:22:33:44:55:66:77:88:99:aa:bb:cc:dd:ee:ff'

    describe 'new', ->

