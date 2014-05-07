describe 'App.Document', ->
  model = null

  beforeEach ->
    model = App.Document.create()

  describe 'parseResultLine', ->
    context 'when given a line with no matches', ->
      it 'returns parsed line with empty matches', ->
        expect(model.parseResultLine('123:sometext')).to.eql
          lineText: 'sometext'
          lineNumber: '123'
          matches: []

    context 'when given a line with no text', ->
      it 'returns parsed line with empty lineText', ->
        expect(model.parseResultLine('123:')).to.eql
          lineText: ''
          lineNumber: '123'
          matches: []

    context 'when given a line with one match', ->
      it 'returns parsed line with single match', ->
        expect(model.parseResultLine('123;2 4:sometext')).to.eql
          lineText: 'sometext'
          lineNumber: '123'
          matches: ['2 4']

    context 'when given a line with multiple matches', ->
      it 'returns parsed line with multiple matches', ->
        expect(model.parseResultLine('123;2 4,3 27:sometext')).to.eql
          lineText: 'sometext'
          lineNumber: '123'
          matches: ['2 4', '3 27']
