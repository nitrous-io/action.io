#= require spec_helper

Tab = Em.Object.extend
  active: false

TabController = Em.ArrayController.extend AIO.IdeTabControllerMixin

describe 'AIO.IdeTabControllerMixin', ->
  controller = null

  beforeEach ->
    controller = TabController.create content: []

  describe '#makeTabActive', ->
    tab1 = tab2 = tab3 = null

    beforeEach ->
      tab1 = Tab.create active: true
      tab2 = Tab.create()
      tab3 = Tab.create()
      controller.set 'content', [tab1, tab2, tab3]

    it 'makes a given tab active', ->
      controller.makeTabActive tab2
      expect(tab1.get 'active').to.be.false
      expect(tab2.get 'active').to.be.true
      expect(tab3.get 'active').to.be.false
      controller.makeTabActive tab3
      expect(tab1.get 'active').to.be.false
      expect(tab2.get 'active').to.be.false
      expect(tab3.get 'active').to.be.true
      controller.makeTabActive tab1
      expect(tab1.get 'active').to.be.true
      expect(tab2.get 'active').to.be.false
      expect(tab3.get 'active').to.be.false

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
          controller.set 'content', [tab1]
          controller.removeTab tab1

        it 'just removes the tab', ->
          expect(controller.get('content').length).to.equal 0
          expect(tab1.get 'active').to.be.false

      context 'when there are many tabs', ->
        beforeEach ->
          controller.set 'content', [tab1, tab2, tab3]

        context 'removing the first tab (2 tabs remaining)', ->
          beforeEach ->
            tab1.set 'active', true
            controller.removeTab tab1

          it 'removes the first tab and makes the second tab active', ->
            expect(controller.get('content').toArray()).to.deep.equal [tab2, tab3]
            expect(tab1.get 'active').to.be.false
            expect(tab2.get 'active').to.be.true
            expect(tab3.get 'active').to.be.false

        context 'removing a tab in the middle', ->
          beforeEach ->
            tab2.set 'active', true
            controller.removeTab tab2

          it 'removes the second tab and makes the third tab active', ->
            expect(controller.get('content').toArray()).to.deep.equal [tab1, tab3]
            expect(tab1.get 'active').to.be.false
            expect(tab2.get 'active').to.be.false
            expect(tab3.get 'active').to.be.true

        context 'removing the last tab', ->
          beforeEach ->
            tab3.set 'active', true
            controller.removeTab tab3

          it 'removes the last tab and makes the second tab active', ->
            expect(controller.get('content').toArray()).to.deep.equal [tab1, tab2]
            expect(tab1.get 'active').to.be.false
            expect(tab2.get 'active').to.be.true
            expect(tab3.get 'active').to.be.false

    context 'when the tab to be removed is inactive', ->
      beforeEach ->
        tab1.set 'active', true
        controller.set 'content', [tab1, tab2, tab3]

      it 'just removes the tab', ->
        controller.removeTab tab2
        expect(controller.get('content').toArray()).to.deep.equal [tab1, tab3]
        expect(tab1.get 'active').to.be.true
        expect(tab2.get 'active').to.be.false
        expect(tab3.get 'active').to.be.false
        controller.removeTab tab3
        expect(controller.get('content').toArray()).to.deep.equal [tab1]
        expect(tab1.get 'active').to.be.true
        expect(tab2.get 'active').to.be.false
        expect(tab3.get 'active').to.be.false

