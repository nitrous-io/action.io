describe 'App.SliderView', ->
  view = null

  beforeEach ->
    view = App.SliderView.create()

  afterEach ->
    view.destroy()

  describe '#valueLabel', ->
    context 'when unit is null', ->
      beforeEach ->
        view.set 'value', 200
        view.set 'unit', null

      it 'does not append the unit', ->
        expect(view.get 'valueLabel').to.equal '200'

    context 'when unit is not null', ->
      beforeEach ->
        view.set 'value', 42
        view.set 'unit', ' MB'

      it 'appends the unit', ->
        expect(view.get 'valueLabel').to.equal '42 MB'

  describe '#updateValueByFraction', ->
    context 'given min, step, and max', ->
      it 'rounds to nearest step', ->
        view.set 'min', 10
        view.set 'max', 110
        view.set 'step', 10

        view.updateValueByFraction 0
        expect(view.get 'value').to.equal 10

        view.updateValueByFraction 1
        expect(view.get 'value').to.equal 110

        view.updateValueByFraction 0.04
        expect(view.get 'value').to.equal 10

        view.updateValueByFraction 0.1
        expect(view.get 'value').to.equal 20

        view.updateValueByFraction 0.5
        expect(view.get 'value').to.equal 60

        view.updateValueByFraction 0.54
        expect(view.get 'value').to.equal 60

        view.updateValueByFraction 0.55
        expect(view.get 'value').to.equal 70

        view.updateValueByFraction 0.6
        expect(view.get 'value').to.equal 70
