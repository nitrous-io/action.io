class AIO.Region extends AIO.Model
  relations: [{
    type: Backbone.HasMany
    key: 'boxes'
    relatedModel: 'AIO.Box'
    includeInJSON: false
    reverseRelation:
      key: 'region'
      keySource: 'region_id'
      includeInJSON: 'id'
  }]

AIO.Region.setup('regions')

