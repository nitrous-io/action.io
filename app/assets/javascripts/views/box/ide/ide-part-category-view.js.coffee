App.IdePartCategoryView = Em.View.extend
  tagName: 'li'
  templateName: 'templates/box/ide/part-category'
  classNames: [ 'ide_parts_category_view' ]

  content: null

  name: (->
    @get 'content.name'
  ).property 'content.name'

  partsCount: (->
    @get('content.parts.length')
  ).property 'content.parts'

  didClick: ->
    @get('parentView').showPartsByCategory @get('name')
