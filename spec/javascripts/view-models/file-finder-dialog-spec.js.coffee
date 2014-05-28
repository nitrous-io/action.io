describe 'App.FileFinderDialog', ->
  model = null
  resultString = "workspace/foo.rb\nworkspace/README.txt\n"
  resultFiles = resultString.trim().split("\n")

  beforeEach ->
    model = App.FileFinderDialog.create()

  describe '#filterResults', ->
    context 'exit conditions', ->
      beforeEach ->
        # set up all necessary conditions
        model.setProperties currentSearch: 'ab', basePath: '.'
        model.setSearchStarted 'ab', '.'
        model.setSearchStarted 'abc', '.'
        model.addResults('ab', '.', resultString)
        model.addResults('abc', '.', resultString)

      it 'is true if all conditions met', ->
        expect(model.filterResults('abc', '.')).to.be.true

      it 'is undefined if no results', ->
        model.set 'results', Em.Object.create()
        expect(model.get('currentResults')).to.be.undefined
        expect(model.filterResults('abc', '.')).to.be.undefined

      it 'is undefined if pattern is too short', ->
        expect(model.filterResults('a', '.')).to.be.undefined

      it 'is undefined if results length is too long', ->
        model.addResults('ab', '.', Array(5).join(resultString))
        expect(model.filterResults('abc', '.')).to.be.undefined

    context 'filtering', ->
      beforeEach ->
        model.setProperties currentSearch: 'qw', basePath: '.'
        model.setSearchStarted 'qw', '.'
        model.addResults('qw', '.', "qwer\nqwert\nqwerty")

      it 'does not filter if all results match', ->
        expect(model.filterResults('qwe', '.')).to.be.true
        expect(model.get('results.qwe\\\\~').mapBy('filename')).to.deep.equal [
          'qwer', 'qwert', 'qwerty']

      it 'fuzzy matches', ->
        expect(model.filterResults('qwt', '.')).to.be.true
        expect(model.get('results.qwt\\\\~').mapBy('filename')).to.deep.equal [
          'qwert', 'qwerty']

      it 'filters away reverse matches', ->
        expect(model.filterResults('qwt', '.')).to.be.true
        expect(model.filterResults('qwte', '.')).to.be.true
        expect(model.get('results.qwte\\\\~')).to.be.null

      it 'can be performed in succession', ->
        patterns = Em.A(['qwe', 'qwer', 'qwert', 'qwerty'])
        patterns.forEach (pattern) ->
          model.setSearchStarted pattern, '.'
          expect(model.filterResults(pattern, '.')).to.be.true
          expect(model.get("results.#{pattern}\\\\~").length).to.above 0

  describe '#currentResults', ->
    it 'computes current results', ->
      expect(model.get('currentResults')).to.be.undefined

      model.setProperties currentSearch: 'ab', basePath: '.'
      expect(model.get('currentResults')).to.be.undefined

      model.setSearchStarted 'ab', '.'
      model.addResults('ab', '.', resultString)
      expect(model.get('currentResults')).to.eq model.get('results.ab\\\\~')

      model.setProperties currentSearch: 'abc', basePath: '.'
      expect(model.get('currentResults')).to.be.undefined

  describe '#addResults', ->
    it 'adds results to the right key', ->
      model.setSearchStarted 'ab', '.'
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
