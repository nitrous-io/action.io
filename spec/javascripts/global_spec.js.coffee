describe 'redirect / navigation helpers', ->
  # these are pretty impractical to test, so just check that they do exist

  describe 'window.redirectTo', ->
    it 'is defined', ->
      expect(window.redirectTo).not.toBe undefined

  describe 'window.navigateTo', ->
    it 'is defined', ->
      expect(window.navigateTo).not.toBe undefined

