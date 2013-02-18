AIO.Router.map ->
  this.resource "boxes", ->
    this.route 'new'
    this.route 'provisioning', path: '/:id/provisioning'

  this.route 'ide', path: 'boxes/:id/ide'

  this.resource 'public_keys', ->
    this.route 'new'
