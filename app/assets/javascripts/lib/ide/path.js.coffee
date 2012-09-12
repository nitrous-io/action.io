AIO.Path = Em.Object.extend
  expanded: false
  absolutePath: ''
  children: null

  init: ->
    @_super()
    @set 'children', [] unless @get 'children'

  directory: (->
    if absolutePath = @get 'absolutePath'
      absolutePath.substr(-1) == '/'
    else
      true
  ).property 'absolutePath'

  name: (->
    if absolutePath = @get 'absolutePath'
      if directory = @get 'directory'
        absolutePath = absolutePath.substr(0, absolutePath.length - 1)
      components = absolutePath.split('/')
      name = components[components.length - 1]
      name += '/' if directory
      name
    else
      '~/'
  ).property 'absolutePath'

