describe 'App.UserColors', ->
  describe '.nextColor', ->
    beforeEach ->
      sinon.stub(App.UserColors, 'colors')
      App.UserColors.colors.returns ['#000', '#001', '#002', '#003']
    afterEach ->
      App.UserColors.colors.restore()

    context 'when started at 0', ->
      it 'cycles through colors', ->
        expect(App.UserColors.nextColor(0)).to.equal '#000'
        expect(App.UserColors.nextColor()).to.equal '#001'
        expect(App.UserColors.nextColor()).to.equal '#002'
        expect(App.UserColors.nextColor()).to.equal '#003'
        expect(App.UserColors.nextColor()).to.equal '#000'

    context 'when started at an index smaller than the number of colors', ->
      it 'cycles through colors from that index', ->
        expect(App.UserColors.nextColor(1)).to.equal '#001'
        expect(App.UserColors.nextColor()).to.equal '#002'
        expect(App.UserColors.nextColor()).to.equal '#003'
        expect(App.UserColors.nextColor()).to.equal '#000'

    context 'when started at an index greater than the number of colors', ->
      it 'cycles through colors from the modulo of the index', ->
        expect(App.UserColors.nextColor(5)).to.equal '#001'
        expect(App.UserColors.nextColor()).to.equal '#002'
        expect(App.UserColors.nextColor()).to.equal '#003'
        expect(App.UserColors.nextColor()).to.equal '#000'
