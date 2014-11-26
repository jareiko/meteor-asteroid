Asteroid.EntityCollection = function EntityCollection(collection) {
  this.collection = collection;
  this.entities = {};
  this.components = [];
  this.subs = [];
  // TODO: Allow customizing the cursor, eg a subset.
  var cursor = collection.find();
  this.handle = cursor.observeChanges({
    added: this.added.bind(this),
    changed: this.changed.bind(this),
    removed: this.removed.bind(this)
  });
};

EntityCollection.prototype.addComponent = function(component) {
  this.components.push(component);
  this.entities.each(function(ent) {
    ent.entComps.push(new component(ent));
  });
};

EntityCollection.prototype.destroy = function() {
  this.handle.stop();
  for (var _id in this.entities) {
    this.removed(_id);
  }
};

EntityCollection.prototype.create = function(doc) {
  if (doc == null) {
    doc = {
      _id: Random.id()
    };
  }
  var ent = new Asteroid.Entity(doc);
  this.components.each(function(component) {
    ent.entComps.push(new component(ent));
  })
  return ent;
};

EntityCollection.prototype.add = function(ent) {
  this.collection.insert(ent.doc);
  this.subs.each(function(sub) {
    sub.added(ent.doc._id, ent.doc);
  });
  return ent;
};

EntityCollection.prototype.added = function(_id, fields) {
  var doc = _.extend({_id: _id}, fields);
  var ent = this.entities[_id] = this.create(doc);
  this.subs.each(function(sub) {
    sub.added(_id, doc);
  });
  return ent;
};

EntityCollection.prototype.changed = function(_id, fields) {
  if (Meteor.isClient) {
    this.entities[_id].changed(fields);
  }
};

EntityCollection.prototype.removed = function(_id) {
  this.entities[_id].removed();
  this.subs.each(function(sub) {
    sub.removed(_id);
  });
  delete this.entities[_id];
};

EntityCollection.prototype.advance = function(delta) {
  for (var _id of this.entities) {
    this.entities[_id].advance(delta);
  }
  for (var _id of this.entities) {
    var cloneDoc = JSON.parse(JSON.stringify(this.entities[_id].doc));
    this.subs.each(function(sub) {
      sub.changed(_id, cloneDoc);
    });
  }
  if (Meteor.isServer) {
    var ent = null;
    var count = 0;
    for (var _id of this.entities) {
      if (Math.random() <= 1 / ++count) {
        ent = e;
      }
    }
    if (ent) {
      this.collection.update(ent.doc._id, ent.doc);
    }
  }
};

EntityCollection.prototype.publish = function(collection, sub) {
  var boundSub = {
    added: sub.added.bind(sub, collection),
    changed: sub.changed.bind(sub, collection),
    removed: sub.removed.bind(sub, collection)
  };
  for (var _id in this.entities) {
    boundSub.added(_id, this.entities[_id].doc);
  }
  sub.ready();
  this.subs.push(boundSub);
};

EntityCollection.prototype.findById = function(_id) {
  return this.entities[_id];
};
