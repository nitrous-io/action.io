AIO.AllPlansController = AIO.ResourceController.extend Em.SortableMixin,
  resourceType: AIO.Plan
  jsonRoot: 'plans'
  sortProperties: ['display_order']

