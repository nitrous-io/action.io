# branch can has parent and child i.e content
#  - when you add a branch to another branch, that branch will have `parent`
#  reference.
#  - a branch is deleted when it is deleted itself or its parent is deleted
AIO.Branch = Em.Mixin.create
  deleted: false
  parent: undefined

  isDeleted: (->
    !!(@get('deleted') || @get('parent.deleted'))
  ).property 'deleted', 'parent'

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
