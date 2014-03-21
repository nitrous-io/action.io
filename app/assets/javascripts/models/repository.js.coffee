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
