describe 'App.FileFinderDialog', ->
  model = null
  resultString = "workspace/foo.rb\nworkspace/README.txt\n"
  resultFiles = resultString.trim().split("\n")

  beforeEach ->
    model = App.FileFinderDialog.create()

  describe '#find', ->
    cbSpy = null

    context 'when results are present', ->
      beforeEach ->
        sinon.stub(model, 'hasResults').returns(true)
        cbSpy = sinon.spy()

      it 'does not run filterResults', ->
        filterSpy = sinon.spy(model, 'filterResults')
        model.find('ab', '.', cbSpy)
        expect(cbSpy).to.not.have.been.called

      it 'does not run callback', ->
        model.find('ab', '.', cbSpy)
        expect(cbSpy).to.not.have.been.called

    context 'when results are absent', ->
      beforeEach ->
        cbSpy = sinon.spy()

      context 'and filterable', ->
        beforeEach ->
          sinon.stub(model, 'filterResults').returns(true)
          cbSpy = sinon.spy()

        it 'does not run callback', ->
          model.find('ab', '.', cbSpy)
          expect(cbSpy).to.not.have.been.called

      context 'and not filterable', ->
        it 'runs callback', ->
          model.find('ab', '.', cbSpy)
          expect(cbSpy).to.have.been.called

        context 'and search status is started', ->
          beforeEach ->
            sinon.stub(model, 'searchStatus').returns('started')

          it 'does not run callback', ->
            model.find('ab', '.', cbSpy)
            expect(cbSpy).not.to.have.been.called

  describe '#filterResults', ->
    context 'exit conditions', ->
      beforeEach ->
        # set up all necessary conditions
        model.setProperties currentSearch: 'ab', basePath: '.'
        model.searchStart 'ab', '.'
        model.searchStart 'abc', '.'
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
        model.searchStart 'qw', '.'
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
          model.searchStart pattern, '.'
          expect(model.filterResults(pattern, '.')).to.be.true
          expect(model.get("results.#{pattern}\\\\~").length).to.above 0

  describe '#searchStatus', ->
    args = ['pattern', 'path']

    it 'returns error when error present', ->
      model.set('error', 'NOPATH')
      expect(model.searchStatus(args...)).to.eq 'error'

    it 'returns unknown if results are undefined', ->
      expect(model.searchStatus(args...)).to.eq 'unknown'

    it 'returns zero if results are empty after search completion', ->
      model.searchComplete args...
      expect(model.searchStatus(args...)).to.eq 'zero'

    it 'returns started if search is started without results yet', ->
      model.searchStart args...
      expect(model.searchStatus(args...)).to.eq 'started'

    it 'returns results if search is started and has results', ->
      model.searchStart args...
      model.addResults(args[0], args[1], "filename\n")
      expect(model.searchStatus(args...)).to.eq 'results'

  describe '#searchStart', ->
    args = ['pattern', 'path']

    context 'when key does not exist', ->
      beforeEach ->
        expect(model.get('newResults')).to.be.undefined
        model.searchStart args...

      it 'sets key to empty array', ->
        expect(model.get(model.resultsKey(args...)) instanceof Array).to.eq true
        expect(model.get(model.resultsKey(args...)).length).to.eq 0

      it 'touches newResults', ->
        expect(model.get('newResults')).to.be.above(Date.now() - 5)

    context 'when key already exists', ->
      beforeEach ->
        model.set model.resultsKey(args...), ["filename"]

      it 'does not change key or touch newResults', ->
        setSpy = sinon.spy(model, 'set')
        model.searchStart args...
        expect(setSpy).to.not.be.called

  describe '#searchComplete', ->
    args = ['pattern', 'path']

    context 'when key does not have results', ->
      beforeEach ->
        model.searchStart args...

      it 'sets key to null', ->
        model.searchComplete args...
        expect(model.get(model.resultsKey(args...))).to.be.null

      it 'touches newResults', ->
        model.searchComplete args...
        expect(model.get('newResults')).to.be.above(Date.now() - 5)

    context 'when key already has results', ->
      beforeEach ->
        model.set model.resultsKey(args...), ["filename"]

      it 'does not change key or touch newResults', ->
        setSpy = sinon.spy(model, 'set')
        model.searchComplete args...
        expect(setSpy).to.not.be.called

  describe '#currentResults', ->
    it 'computes current results', ->
      expect(model.get('currentResults')).to.be.undefined

      model.setProperties currentSearch: 'ab', basePath: '.'
      expect(model.get('currentResults')).to.be.undefined

      model.searchStart 'ab', '.'
      model.addResults('ab', '.', resultString)
      expect(model.get('currentResults')).to.eq model.get('results.ab\\\\~')

      model.setProperties currentSearch: 'abc', basePath: '.'
      expect(model.get('currentResults')).to.be.undefined

  describe '#addResults', ->
    it 'adds results to the right key', ->
      model.searchStart 'ab', '.'
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
