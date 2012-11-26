# branch can has parent and child i.e content
#  - when you add a branch to another branch, that branch will have `parent`
#  reference.
#  - a branch is deleted when it is deleted itself or its parent is deleted
AIO.Branch = Em.Mixin.create
  shouldBeDeleted: false
  deleted: false
  parent: undefined

  deletedDidChange: (->
    deleted = !!(@get('deleted') || @get('parent.shouldBeDeleted'))
    @set 'shouldBeDeleted', deleted
  ).observes 'deleted', 'parent.shouldBeDeleted'

  addObject: (object) ->
    object.set "parent", @
    @_super(object)

  pushObject: (object) ->
    object.set "parent", @
    @_super(object)

  removeObject: (object) ->
    object.set "parent", undefined
    @_super(object)

  updateChildAboutParent: ->
    @get('content').forEach (path) => path.set "parent", @
