Em.Resource.reopen({
  findResource: function() {
    var self = this;

    return this._resourceRequest({type: 'GET'})
      .done(function(json) {
        json = json[self.get('resourceName')];
        self.deserialize(json);
      });
  },

  saveResource: function() {
    var self = this;

    if (this.validate !== undefined) {
      var error = this.validate();
      if (error) {
        return {
          fail: function(f) { f(error); return this; },
          done: function() { return this; },
          always: function(f) { f(); return this; }
        };
      }
    }

    return this._resourceRequest({type: this.isNew() ? 'POST' : 'PUT',
                                  data: this.serialize()})
      .done(function(json) {
        // Update properties
        if (json) {
          json = json[self.get('resourceName')];
          self.deserialize(json);
        }
      });
  },

  serialize: function() {
    var name = this.resourceName,
        props = this.resourceProperties,
        prop,
        ret = {};

    ret[name] = {};
    for(var i = 0; i < props.length; i++) {
      prop = props[i];
      if(serialized = this.serializeProperty(prop)) {
        ret[name][prop] = serialized;
      }
    }
    return ret;
  }
});

Em.ResourceController.reopen({
  load: function(json) {
    var resource = this.get('resourceType').create().deserialize(json);
    this.pushObject(resource);
  },

  loadAll: function(json) {
    json = json[this.get('jsonRoot')];
    for (var i=0; i < json.length; i++)
      this.load(json[i]);
  },

  findAll: function() {
    var self = this;

    return this._resourceRequest({type: 'GET'})
      .done(function(json) {
        self.clearAll();
        self.loadAll(json);
      });
  }
});
