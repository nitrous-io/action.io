describe 'AIO.authToken', ->
  describe '.obtain', ->
    context 'when GET request fails', ->
      beforeEach ->
        server.respondWith 'GET', '/auth_token/rainbow', [
          400
          { 'Content-Type': 'application/json; charset=utf-8' }
          '{ "error": "failed." }'
        ]

      it 'calls callback with error', (done) ->
        AIO.authToken.obtain 'rainbow', (err, authToken) ->
          expect(err).to.be.an.instanceOf Error
          expect(err.jqXHR.status).to.equal 400
          expect(authToken).not.to.exist
          done()
        server.respond()

    context 'when GET request does not contain auth token', ->
      beforeEach ->
        server.respondWith 'GET', '/auth_token/rainbow', [
          200
          { 'Content-Type': 'application/json; charset=utf-8' }
          '{ "nada": null }'
        ]

      it 'calls callback with error', (done) ->
        AIO.authToken.obtain 'rainbow', (err, authToken) ->
          expect(err).to.be.an.instanceOf Error
          expect(authToken).not.to.exist
          done()
        server.respond()

    context 'when GET request contains auth token', ->
      beforeEach ->
        server.respondWith 'GET', '/auth_token/rainbow', [
          200
          { 'Content-Type': 'application/json; charset=utf-8' }
          '{ "auth_token": "AbCdEfG1234567" }'
        ]

      it 'calls callback with auth token', (done) ->
        AIO.authToken.obtain 'rainbow', (err, authToken) ->
          expect(err).not.to.exist
          expect(authToken).to.equal 'AbCdEfG1234567'
          done()
        server.respond()
