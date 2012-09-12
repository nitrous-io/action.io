Tab = Em.Object.extend
  active: false

describe 'AIO.IdeTabView', ->
  view = null

  beforeEach ->
    view = AIO.IdeTabView.create()

  describe '#makeTabActive', ->
    tab1 = tab2 = tab3 = null

    beforeEach ->
      tab1 = Tab.create(active: true)
      tab2 = Tab.create()
      tab3 = Tab.create()
      view.set 'tabs', [tab1, tab2, tab3]

    it 'makes a given tab active', ->
      view.makeTabActive(tab2)
      expect(tab1.get('active')).to.be.false
      expect(tab2.get('active')).to.be.true
      expect(tab3.get('active')).to.be.false
      view.makeTabActive(tab3)
      expect(tab1.get('active')).to.be.false
      expect(tab2.get('active')).to.be.false
      expect(tab3.get('active')).to.be.true
      view.makeTabActive(tab1)
      expect(tab1.get('active')).to.be.true
      expect(tab2.get('active')).to.be.false
      expect(tab3.get('active')).to.be.false

  describe '#removeTab', ->
    tab1 = tab2 = tab3 = null

    beforeEach ->
      tab1 = Tab.create()
      tab2 = Tab.create()
      tab3 = Tab.create()

    context 'when the tab to be removed is active', ->
      context 'when there is only one tab', ->
        beforeEach ->
          tab1.set 'active', true
          view.set 'tabs', [tab1]
          view.removeTab(tab1)

        it 'just removes the tab', ->
          expect(view.get('tabs').length).to.equal 0
          expect(tab1.get('active')).to.be.false

      context 'when there are many tabs', ->
        beforeEach ->
          view.set 'tabs', [tab1, tab2, tab3]

        context 'removing the first tab (2 tabs remaining)', ->
          beforeEach ->
            tab1.set 'active', true
            view.removeTab(tab1)

          it 'removes the first tab and makes the second tab active', ->
            expect(view.get('tabs').toArray()).to.deep.equal [tab2, tab3]
            expect(tab1.get('active')).to.be.false
            expect(tab2.get('active')).to.be.true
            expect(tab3.get('active')).to.be.false

        context 'removing a tab in the middle', ->
          beforeEach ->
            tab2.set 'active', true
            view.removeTab(tab2)

          it 'removes the second tab and makes the third tab active', ->
            expect(view.get('tabs').toArray()).to.deep.equal [tab1, tab3]
            expect(tab1.get('active')).to.be.false
            expect(tab2.get('active')).to.be.false
            expect(tab3.get('active')).to.be.true

        context 'removing the last tab', ->
          beforeEach ->
            tab3.set 'active', true
            view.removeTab(tab3)

          it 'removes the last tab and makes the second tab active', ->
            expect(view.get('tabs').toArray()).to.deep.equal [tab1, tab2]
            expect(tab1.get('active')).to.be.false
            expect(tab2.get('active')).to.be.true
            expect(tab3.get('active')).to.be.false

    context 'when the tab to be removed is inactive', ->
      beforeEach ->
        tab1.set 'active', true
        view.set 'tabs', [tab1, tab2, tab3]

      it 'just removes the tab', ->
        view.removeTab(tab2)
        expect(view.get('tabs').toArray()).to.deep.equal [tab1, tab3]
        expect(tab1.get('active')).to.be.true
        expect(tab2.get('active')).to.be.false
        expect(tab3.get('active')).to.be.false
        view.removeTab(tab3)
        expect(view.get('tabs').toArray()).to.deep.equal [tab1]
        expect(tab1.get('active')).to.be.true
        expect(tab2.get('active')).to.be.false
        expect(tab3.get('active')).to.be.false

