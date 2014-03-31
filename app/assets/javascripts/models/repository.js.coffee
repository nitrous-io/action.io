AIO.Repository = AIO.Resource.extend
  box_id: null
  name: null
  full_name: null
  clone_url: null
  state: null
  private: null
  cloned_at: null
  created_at: null
  scm: null
  failure_reason: null

  # true if we're waiting on the result of an identify() call
  identifying: false

  # Observe this to know when repo identification is complete.  Set by shover, can also be set manually to short-circuit identification process
  identified: false

  resourceUrl: '/repositories'
  resourceName: 'repository'
  resourceProperties: ['clone_url', 'box_id']

  box: (->
    AIO.get('router.boxesController').findById @get('box_id')
  ).property 'box_id'

  displayName: (->
    if @get('author') && @get('shortName')
      "#{@get 'author'}/#{@get 'shortName'}"
  ).property 'author', 'shortName'

  shortName: (->
    tokens = @get 'tokenizedCloneURL'
    tokens?.name
  ).property 'clone_url'

  author: (->
    tokens = @get 'tokenizedCloneURL'
    tokens?.author
  ).property 'clone_url'

  failed: (->
    @get('state') == 'failed'
  ).property 'state'

  supported: (->
    _.include(['git', 'mercurial'], @get('scm'))
  ).property 'scm'

  isGithub: (->
    @get('tokenizedCloneURL.author')? && @get('clone_url').match(/github\.com/)?
  ).property 'clone_url'

  tokenizedCloneURL: (->
    url = @get('clone_url')
    regex = ///
      ([^/]+)   # Last block before a "/"
      /
      ([^/]+?)  # Last block after a "/"
      (.git)?$  # Optionally ending with ".git"
    ///
    matches = url.match(regex)
    if matches
      {
        author: matches[1]
        name: matches[2]
      }
  ).property 'clone_url'

  identify: (callback) ->
    @set 'identifying', true
    data = repository:
      clone_url: @get('clone_url')
    data['repository']['box_id'] = @get('box_id') if @get('box_id')?
    $.ajax(
      type: 'POST'
      dataType: 'json'
      data: data
      url: "/repositories/identify_scm"
    ).done (json) ->
      callback(json)
    .fail (e) ->
      json = $.parseJSON e.responseText
      callback(json)

  makeIdentified: ->
    @set 'identifying', false
    @set 'identified', true

