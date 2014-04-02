App.BoxesNewController = Em.ObjectController.extend
  boxNamePlaceholder: 'my-awesome-box'
  isIntro: false
  closestRegionId: null
  boxNameIsDirty: false # true if user has changed box name herself
  repo: new App.Repository
  identifyTimedOut: false

  showCloneUrl: false

  closestRegionIdDidChange: (->
    @preselectRegion()
  ).observes 'closestRegionId'

  boxTemplateIdDidChange: (->
    return unless box = @get 'content'
    return if @get('boxNameIsDirty')
    randomName = box.randomName()

    if existingBox = App.get('boxes').findProperty 'name', randomName
      randomName = "#{randomName}-1"

    @set 'name', randomName
  ).observes 'content.box_template_id'

  boxTemplateSelected: (->
    box = @get 'content'
    if box.get 'box_template_id'
      box.set 'source_snapshot_id', null
  ).observes 'content.box_template_id'

  sourceSnapshotSelected: (->
    box = @get 'content'
    if box.get 'source_snapshot_id'
      box.set 'box_template_id', null
    else
      box.set 'box_template_id', App.get('boxTemplates.firstObject.id')
  ).observes 'content.source_snapshot_id'

  newRecord: ->
    @set 'content', box = App.Box.create()
    @preselectRegion()
    @handleIntent()

  save: ->
    record = @get 'content'
    repo = @get 'repo'

    doSave = =>
      record.save().then =>
        page = 'boxes.provisioning'
        page = 'intro.n2o' if @get 'isIntro'
        App.get('router').transitionTo page, id: record.get 'id'

    if repository_clone_url = @get('content.repository_clone_url')
      repo.set 'clone_url', repository_clone_url
      repo.identify (e) =>
        if e?
          @set 'content.saving', false
          @set 'content.errors',
            repository_clone_url: ['does not look like a Git or Mercurial repository']
        else
          record.repository_to_clone =
            clone_url: repo.get('clone_url')
            state: repo.get('state')
            scm: repo.get('scm')
          doSave()
    else
      doSave()

  cancel: ->
    App.get('router').transitionTo 'boxes.index'

  preselectRegion: ->
    box = @get 'content'
    return if box.get 'region_id' # Don't interfere with user's selection.
    if regionId = @get 'closestRegionId'
      box.set 'region_id', regionId
      return
    App.Region.fetchClosestRegion()

  handleIntent: ->
    box = @get 'content'
    if cloneURL = App.get('currentUser').get('intendedCloneRepoURL')
      @set 'showCloneUrl', true # TODO remove this line (and the showCloneUrl declaration at top of file) once clone feature is live for everyone
      box.set 'repository_clone_url', cloneURL

    if boxTemplate = App.get('currentUser').get('intendedBoxTemplate')
      box.set 'box_template_id', boxTemplate.get('id')
    else
      box.set 'box_template_id', App.get('boxTemplates.firstObject.id')
