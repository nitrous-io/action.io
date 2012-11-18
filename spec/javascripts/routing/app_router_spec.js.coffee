#require 'spec_helper'

describe 'AIO.Router', ->
  router = null
  getCurrentPath = -> router.get("currentState.path")

  beforeEach ->
    router = AIO.get 'router'

  describe "/", ->
    it 'is boxes.index', ->
      Em.run -> router.route('/')
      expect(getCurrentPath()).to.eql("root.boxes.index")

  describe "/boxes", ->
    it 'is boxes.index', ->
      Em.run -> router.route('/boxes')
      expect(getCurrentPath()).to.eql("root.boxes.index")

  describe "/boxes/new", ->
    it 'is boxes.new', ->
      Em.run -> router.route('/boxes/new')
      expect(getCurrentPath()).to.eql("root.boxes.new")

  describe "/boxes/:id/provisioning", ->
    it 'is boxes.provisioning', ->
      Em.run -> router.route('/boxes/1/provisioning')
      expect(getCurrentPath()).to.eql("root.boxes.provisioning")

  describe "/boxes/:id/ide", ->
    it 'is boxes.ide', ->
      Em.run -> router.route('/boxes/1/ide')
      expect(getCurrentPath()).to.eql("root.boxes.ide")

  describe "/public_keys", ->
    it 'is publicKeys.index', ->
      Em.run -> router.route('/public_keys')
      expect(getCurrentPath()).to.eql("root.publicKeys.index")

  describe "/public_keys/new", ->
    it 'is publicKeys.new', ->
      Em.run -> router.route('/public_keys/new')
      expect(getCurrentPath()).to.eql("root.publicKeys.new")

