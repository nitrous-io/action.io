describe 'aio.models.User', ->
  user = null

  before ->
    user = new aio.models.User

  describe '#hasGitHub', ->
    context 'when no authentication exists', ->
      before ->
        user.unset('authentications')

      it 'returns false', ->
        expect(user.hasGitHub()).toBe false

    context 'when an authentication with the provider "github" does not exist', ->
      before ->
        user.set('authentications', [{ provider: 'google' }, { provider: 'twitter' }])

      it 'returns false', ->
        expect(user.hasGitHub()).toBe false

    context 'when an authentication with the provider "github" exists', ->
      before ->
        user.set('authentications', [{ provider: 'google' }, { provider: 'github' }])

      it 'returns true', ->
        expect(user.hasGitHub()).toBe true

