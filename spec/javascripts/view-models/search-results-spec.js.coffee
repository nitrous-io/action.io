describe 'App.SearchResults', ->
  model = null

  beforeEach ->
    model = App.SearchResults.create()

  describe 'parseResultLine', ->
    context 'when given a line with no matches', ->
      it 'returns parsed line with empty matches', ->
        [parsedLine, matchCount] = model.parseResultLine('123:sometext')
        expect(parsedLine.lineParts).to.eql [{text: 'sometext', match: false}]
        expect(parsedLine.lineNumber).to.eql '123'
        expect(matchCount).to.eql 0

    context 'when given a line with no text', ->
      it 'returns parsed line with empty lineText', ->
        [parsedLine, matchCount] = model.parseResultLine('123:')
        expect(parsedLine.lineParts).to.eql []
        expect(parsedLine.lineNumber).to.eql '123'
        expect(matchCount).to.eql 0

    context 'when given a line with one match', ->
      it 'in middle of string works', ->
        [parsedLine, matchCount] = model.parseResultLine('123;2 4:sometext')
        expect(parsedLine.lineParts[0].text).to.eq 'so'
        expect(parsedLine.lineParts[0].match).to.eq false
        expect(parsedLine.lineParts[1].text).to.eq 'mete'
        expect(parsedLine.lineParts[1].match).to.eq true
        expect(parsedLine.lineParts[2].text).to.eq 'xt'
        expect(parsedLine.lineParts[2].match).to.eq false
        expect(parsedLine.lineNumber).to.eql '123'
        expect(matchCount).to.eql 1

      it 'at beginning of string', ->
        [parsedLine, matchCount] = model.parseResultLine('321;0 3:sometext')
        expect(parsedLine.lineParts[0].text).to.eq 'som'
        expect(parsedLine.lineParts[0].match).to.eq true
        expect(parsedLine.lineParts[1].text).to.eq 'etext'
        expect(parsedLine.lineParts[1].match).to.eq false
        expect(parsedLine.lineNumber).to.eql '321'
        expect(matchCount).to.eql 1

      it 'at end of string', ->
        [parsedLine, matchCount] = model.parseResultLine('321;4 4:sometext')
        expect(parsedLine.lineParts[0].text).to.eq 'some'
        expect(parsedLine.lineParts[0].match).to.eq false
        expect(parsedLine.lineParts[1].text).to.eq 'text'
        expect(parsedLine.lineParts[1].match).to.eq true
        expect(parsedLine.lineNumber).to.eql '321'
        expect(matchCount).to.eql 1

      it 'with UTF-8 in the line', ->
        [parsedLine, matchCount] = model.parseResultLine('31;23 8:* データファイルdatafile')
        expect(parsedLine.lineParts[0].text).to.eq '* データファイル'
        expect(parsedLine.lineParts[0].match).to.eq false
        expect(parsedLine.lineParts[1].text).to.eq 'datafile'
        expect(parsedLine.lineParts[1].match).to.eq true
        expect(parsedLine.lineParts[2]).to.eq undefined

    context 'when given a line with multiple matches', ->
      it 'returns parsed line with multiple matches', ->
        [parsedLine, matchCount] = model.parseResultLine('123;2 4,7 4:a long lang string')
        expect(parsedLine.lineParts[0].text).to.eq 'a '
        expect(parsedLine.lineParts[0].match).to.eq false
        expect(parsedLine.lineParts[1].text).to.eq 'long'
        expect(parsedLine.lineParts[1].match).to.eq true
        expect(parsedLine.lineParts[2].text).to.eq ' '
        expect(parsedLine.lineParts[2].match).to.eq false
        expect(parsedLine.lineParts[3].text).to.eq 'lang'
        expect(parsedLine.lineParts[3].match).to.eq true
        expect(parsedLine.lineParts[4].text).to.eq ' string'
        expect(parsedLine.lineParts[4].match).to.eq false
        expect(parsedLine.lineNumber).to.eql '123'
        expect(matchCount).to.eql 2

      it 'of length one each', ->
        [parsedLine, matchCount] = model.parseResultLine('123;0 1,1 1,2 1,3 1:abcd')
        expect(_.pluck(parsedLine.lineParts, 'text')).to.eql ['a', 'b', 'c', 'd']
        expect(_.pluck(parsedLine.lineParts, 'match')).to.eql [true, true, true, true]
        expect(matchCount).to.eql 4

      it 'with UTF-8 in search term', ->
        [parsedLine, matchCount] = model.parseResultLine('31;11 12,55 12:* データファイルdatafile(例: データベースファイル)')
        expect(parsedLine.lineParts[0].text).to.eq '* データ'
        expect(parsedLine.lineParts[0].match).to.eq false
        expect(parsedLine.lineParts[1].text).to.eq 'ファイル'
        expect(parsedLine.lineParts[1].match).to.eq true
        expect(parsedLine.lineParts[2].text).to.eq 'datafile(例: データベース'
        expect(parsedLine.lineParts[2].match).to.eq false
        expect(parsedLine.lineParts[3].text).to.eq 'ファイル'
        expect(parsedLine.lineParts[3].match).to.eq true
        expect(parsedLine.lineParts[4].text).to.eq ')'
        expect(parsedLine.lineParts[4].match).to.eq false
        expect(matchCount).to.eql 2
