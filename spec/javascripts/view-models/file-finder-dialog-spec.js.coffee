describe 'App.FileFinderDialog', ->
  model = null
  resultString = "workspace/foo.rb\nworkspace/README.txt\n"
  resultFiles = resultString.trim().split("\n")

  beforeEach ->
    model = App.FileFinderDialog.create()

  describe '#currentResults', ->
    it 'computes current results', ->
      expect(model.get('currentResults')).to.eq undefined

      model.setProperties currentSearch: 'ab', basePath: '.'
      expect(model.get('currentResults')).to.eq undefined

      model.addResults('ab', '.', resultString)
      expect(model.get('currentResults')).to.eq model.get('results.ab\\\\~')

      model.setProperties currentSearch: 'abc', basePath: '.'
      expect(model.get('currentResults')).to.eq undefined

  describe '#addResults', ->
    it 'adds results to the right key', ->
      model.addResults('ab', '.', resultString)
      expect(model.get("results.ab\\\\~").mapBy('filename')).to.deep.equal resultFiles

  describe '#hasResults', ->
    beforeEach ->
      sinon.stub(App.FileFindCommand, 'keyFor').returns('KEY')

    afterEach ->
      App.FileFindCommand.keyFor.restore()

    it 'returns true if results are present', ->
      model.set('results.KEY', [1, 2, 3])
      expect(model.hasResults('stub', 'stub')).to.be.ok

    it 'returns false if results are absent or empty', ->
      expect(model.hasResults('stub', 'stub')).to.not.be.ok

      model.set('results.KEY', [])
      expect(model.hasResults('stub', 'stub')).to.not.be.ok
