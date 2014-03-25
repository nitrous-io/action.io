AIO.BoxesNewController = Em.ObjectController.extend
  boxNamePlaceholder: 'my-awesome-box'
  isIntro: false
  closestRegionId: null
  boxNameIsDirty: false # true if user has changed box name herself
  repo: new AIO.Repository

  closestRegionIdDidChange: (->
    this.preselectRegion()
  ).observes 'closestRegionId'

  boxTemplateIdDidChange: (->
    return if @get('boxNameIsDirty')
    randomName = @get('content').randomName()
    boxes = AIO.get('router.boxesController.content') || []

    existingBox = _.find boxes, (box) -> box.name == randomName
    if existingBox
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
      box.set 'box_template_id', AIO.get('router.boxTemplatesController.firstObject.id')
  ).observes 'content.source_snapshot_id'

  triggerSaveBox: (->
    repo = @get('repo')
    if @get('content.saving') && @get('repo.identified') == true
      if repo.supported()
        Ember.run.once(this, 'saveBox')
      else
        @set('content.saving', false)
        @set 'content.errors',
          repository_clone_url: ['does not look like a Git or Mercurial repository']
  ).observes 'content.saving', 'repo.identified'

  newRecord: ->
    box = AIO.Box.create()
    @set 'content', box
    box.set 'box_template_id', AIO.get('router.boxTemplatesController.firstObject.id')
    this.preselectRegion()
    this.handleIntent()

  save: ->
    record = @get 'content'
    record.set 'saving', true

    if !record.get('repository_clone_url')?.length
      @repo.makeIdentified # trigger saveBox
      return

    # validate before identify wait
    errors = record.validate()
    if errors?
      record.set 'saving', false
      return

    this.identifyRepo()

    Ember.run.later(this, ->
      if @get('repo.identified') == true || @get('repo.identifying') == false
        return
      @repo.makeIdentified # trigger saveBox
      AIO.set 'flashMessage', { type: 'alert-error', text: "Verifying #{@get('content.repository_clone_url')} took too long.  We have created your box; you can try cloning the repository from the console" }
    , 30 * 1000) # 30 seconds

  identifyRepo: ->
    @get('repo').set('clone_url', @get('content.repository_clone_url'))
    @get('repo').identify (e) =>
      @set('content.saving', false)
      @set('content.errors', $.parseJSON(e.responseText).errors)

  saveBox: ->
    record = @get 'content'
    repo = @get 'repo'
    record.repository_to_clone =
      clone_url: repo.clone_url
      state: repo.state
      scm: repo.scm
    record.saveResource()
      .fail (e) ->
        if e.status == 422
          record.set 'errors', $.parseJSON(e.responseText).errors
      .done =>
        AIO.get('router.boxesController').addObject record

        page = 'boxes.provisioning'
        page = 'intro.n2o' if @get 'isIntro'

        AIO.get('router').transitionTo page, id: record.get 'id'
      .always ->
        record.set 'saving', false

  cancel: ->
    AIO.get('router').transitionTo 'boxes.index'

  preselectRegion: ->
    box = @get 'content'
    return if box.get 'region_id' # Don't interfere with user's selection.
    if regionId = @get 'closestRegionId'
      box.set 'region_id', regionId
      return
    AIO.Region.fetchClosestRegion()

  handleIntent: ->
    box = @get 'content'
    if cloneURL = AIO.get('currentUser').get('intendedCloneRepoURL')
      box.set 'repository_clone_url', cloneURL
