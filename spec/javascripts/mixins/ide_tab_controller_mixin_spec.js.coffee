Tab = Em.Object.extend
  active: false
  focused: false

TabController = Em.ArrayController.extend App.IdeTabControllerMixin

describe 'App.IdeTabControllerMixin', ->
  controller = null

  beforeEach ->
    controller = TabController.create content: []

  describe '#makeTabActive', ->
    tab1 = tab2 = tab3 = null

    beforeEach ->
      tab1 = Tab.create active: true, focused: true
      tab2 = Tab.create()
      tab3 = Tab.create()
      controller.set 'content', [tab1, tab2, tab3]

    it 'makes a given tab active', (done) ->
      controller.makeTabActive tab2
      Em.run.next ->
        expect(tab1.get 'active').to.be.false
        expect(tab2.get 'active').to.be.true
        expect(tab3.get 'active').to.be.false
        expect(tab1.get 'focused').to.be.false
        expect(tab2.get 'focused').to.be.true
        expect(tab3.get 'focused').to.be.false

        controller.makeTabActive tab3
        Em.run.next ->
          expect(tab1.get 'active').to.be.false
          expect(tab2.get 'active').to.be.false
          expect(tab3.get 'active').to.be.true
          expect(tab1.get 'focused').to.be.false
          expect(tab2.get 'focused').to.be.false
          expect(tab3.get 'focused').to.be.true

          controller.makeTabActive tab1
          Em.run.next ->
            expect(tab1.get 'active').to.be.true
            expect(tab2.get 'active').to.be.false
            expect(tab3.get 'active').to.be.false
            expect(tab1.get 'focused').to.be.true
            expect(tab2.get 'focused').to.be.false
            expect(tab3.get 'focused').to.be.false
            done()

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
          tab1.set 'focused', true
          controller.set 'content', [tab1]
          controller.removeTab tab1

        it 'just removes the tab', ->
          expect(controller.get('content').length).to.equal 0

      context 'when there are many tabs', ->
        beforeEach ->
          controller.set 'content', [tab1, tab2, tab3]

        context 'removing the first tab (2 tabs remaining)', ->
          beforeEach ->
            tab1.set 'active', true
            tab1.set 'focused', true
            controller.removeTab tab1

          it 'removes the first tab and makes the second tab active', (done) ->
            Em.run.next ->
              expect(controller.get('content').toArray()).to.deep.equal [tab2, tab3]
              expect(tab1.get 'active').to.be.false
              expect(tab2.get 'active').to.be.true
              expect(tab3.get 'active').to.be.false
              expect(tab1.get 'focused').to.be.false
              expect(tab2.get 'focused').to.be.true
              expect(tab3.get 'focused').to.be.false
              done()

        context 'removing a tab in the middle', ->
          beforeEach ->
            tab2.set 'active', true
            tab2.set 'focused', true
            controller.removeTab tab2

          it 'removes the second tab and makes the third tab active', (done) ->
            Em.run.next ->
              expect(controller.get('content').toArray()).to.deep.equal [tab1, tab3]
              expect(tab1.get 'active').to.be.false
              expect(tab2.get 'active').to.be.false
              expect(tab3.get 'active').to.be.true
              expect(tab1.get 'focused').to.be.false
              expect(tab2.get 'focused').to.be.false
              expect(tab3.get 'focused').to.be.true
              done()

        context 'removing the last tab', ->
          beforeEach ->
            tab3.set 'active', true
            tab3.set 'focused', true
            controller.removeTab tab3

          it 'removes the last tab and makes the second tab active', (done) ->
            Em.run.next ->
              expect(controller.get('content').toArray()).to.deep.equal [tab1, tab2]
              expect(tab1.get 'active').to.be.false
              expect(tab2.get 'active').to.be.true
              expect(tab3.get 'active').to.be.false
              expect(tab1.get 'focused').to.be.false
              expect(tab2.get 'focused').to.be.true
              expect(tab3.get 'focused').to.be.false
              done()

    context 'when the tab to be removed is inactive', ->
      beforeEach ->
        tab1.set 'active', true
        tab1.set 'focused', true
        controller.set 'content', [tab1, tab2, tab3]

      it 'just removes the tab', ->
        controller.removeTab tab2
        expect(controller.get('content').toArray()).to.deep.equal [tab1, tab3]
        expect(tab1.get 'active').to.be.true
        expect(tab2.get 'active').to.be.false
        expect(tab3.get 'active').to.be.false
        expect(tab1.get 'focused').to.be.true
        expect(tab2.get 'focused').to.be.false
        expect(tab3.get 'focused').to.be.false

        controller.removeTab tab3
        expect(controller.get('content').toArray()).to.deep.equal [tab1]
        expect(tab1.get 'active').to.be.true
        expect(tab2.get 'active').to.be.false
        expect(tab3.get 'active').to.be.false
        expect(tab1.get 'focused').to.be.true
        expect(tab2.get 'focused').to.be.false
        expect(tab3.get 'focused').to.be.false

  describe '#makeNextTabActive', ->
    tab1 = tab2 = tab3 = null

    beforeEach ->
      tab1 = Tab.create active: true, focused: true
      tab2 = Tab.create()
      tab3 = Tab.create()
      controller.set 'content', [tab1, tab2, tab3]

    it 'makes the next tab active', (done) ->
      controller.makeNextTabActive()
      Em.run.next ->
        expect(tab1.get 'active').to.be.false
        expect(tab2.get 'active').to.be.true
        expect(tab3.get 'active').to.be.false
        expect(tab1.get 'focused').to.be.false
        expect(tab2.get 'focused').to.be.true
        expect(tab3.get 'focused').to.be.false

        controller.makeNextTabActive()
        Em.run.next ->
          expect(tab1.get 'active').to.be.false
          expect(tab2.get 'active').to.be.false
          expect(tab3.get 'active').to.be.true
          expect(tab1.get 'focused').to.be.false
          expect(tab2.get 'focused').to.be.false
          expect(tab3.get 'focused').to.be.true

          controller.makeNextTabActive()
          Em.run.next ->
            expect(tab1.get 'active').to.be.true
            expect(tab2.get 'active').to.be.false
            expect(tab3.get 'active').to.be.false
            expect(tab1.get 'focused').to.be.true
            expect(tab2.get 'focused').to.be.false
            expect(tab3.get 'focused').to.be.false
            done()

  describe '#makePreviousTabActive', ->
    tab1 = tab2 = tab3 = null

    beforeEach ->
      tab1 = Tab.create active: true, focused: true
      tab2 = Tab.create()
      tab3 = Tab.create()
      controller.set 'content', [tab1, tab2, tab3]

    it 'makes the previous tab active', (done) ->
      controller.makePreviousTabActive()
      Em.run.next ->
        expect(tab1.get 'active').to.be.false
        expect(tab2.get 'active').to.be.false
        expect(tab3.get 'active').to.be.true
        expect(tab1.get 'focused').to.be.false
        expect(tab2.get 'focused').to.be.false
        expect(tab3.get 'focused').to.be.true

        controller.makePreviousTabActive()
        Em.run.next ->
          expect(tab1.get 'active').to.be.false
          expect(tab2.get 'active').to.be.true
          expect(tab3.get 'active').to.be.false
          expect(tab1.get 'focused').to.be.false
          expect(tab2.get 'focused').to.be.true
          expect(tab3.get 'focused').to.be.false

          controller.makePreviousTabActive()
          Em.run.next ->
            expect(tab1.get 'active').to.be.true
            expect(tab2.get 'active').to.be.false
            expect(tab3.get 'active').to.be.false
            expect(tab1.get 'focused').to.be.true
            expect(tab2.get 'focused').to.be.false
            expect(tab3.get 'focused').to.be.false
            done()

