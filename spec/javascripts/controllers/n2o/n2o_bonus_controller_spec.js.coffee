describe 'AIO.N2oBonusController', ->
  controller = bonus = null

  beforeEach ->
    bonus = AIO.Bonus.create()
    controller = AIO.N2oBonusController.create content: bonus

  describe '#reload', ->
    attrs =
      id: 1
      invite_friends: "2013-01-19T00:00:00Z"
      github:         "2013-02-18T00:00:00Z"
      twitter:        "2013-03-17T00:00:00Z"
      facebook:       "2013-04-16T00:00:00Z"
      linkedin:       "2013-05-15T00:00:00Z"

    beforeEach ->
      server.respondWith 'GET', '/bonus', [
        200
        { 'Content-Type': 'application/json; charset=utf-8' }
        JSON.stringify({bonus: attrs})
      ]

    it 'fetches and reloads bonus object', ->
      controller.reload()
      server.respond()
      content = controller.get 'content'
      expect(content.get 'id').to.equal attrs.id
      expect(content.get 'invite_friends').to.equal attrs.invite_friends
      expect(content.get 'github'  ).to.equal attrs.github
      expect(content.get 'twitter' ).to.equal attrs.twitter
      expect(content.get 'facebook').to.equal attrs.facebook
      expect(content.get 'linkedin').to.equal attrs.linkedin
