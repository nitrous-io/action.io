AIO.Org = AIO.Resource.extend
  name            : null
  billing_email   : null

  resourceUrl: '/orgs'
  resourceName: 'org'
  resourceProperties: ['name', 'billing_email']

  validations:
    name: (v) -> "can't be blank" unless v && v.length > 0
    billing_email: (v) -> "can't be blank" unless v && v.length > 0

  permalink: (->
    name = @get('name')
    name = "" unless name?
    name.toLowerCase().replace(/\W|_/g, ' ').replace(/\s+/g, ' ').trim().replace(/\s/g, '-')
  ).property 'name'
