var EntityCollection =
    Asteroid.EntityCollection = function EntityCollection(collection) {
  this.collection = collection;
  this.entities = {};
  this.components = [];
  this.subs = [];
  // TODO: Allow customizing the cursor, eg a subset.
  var cursor = collection.find();
  var entColl = this;
  this.handle = cursor.observeChanges({
    added: function(_id, fields) {
      var doc = _.extend({_id: _id}, fields);
      var ent = entColl.entities[_id] = entColl.create(doc);
      entColl.subs.forEach(function(sub) {
        sub.added(_id, doc);
      });
      return ent;
    },
    changed: function(_id, fields) {
      if (Meteor.isClient) {
        entColl.entities[_id].changed(fields);
      }
    },
    removed: function(_id) {
      entColl.entities[_id].removed();
      entColl.subs.forEach(function(sub) {
        sub.removed(_id);
      });
      delete entColl.entities[_id];
    }
  });
};

EntityCollection.prototype.addComponent = function(component) {
  this.components.push(component);
  for (var _id in this.entities) {
    var ent = this.entities[_id];
    ent.entComps.push(new component(ent));
  }
};

EntityCollection.prototype.create = function(doc) {
  if (doc == null) {
    doc = {
      _id: Random.id()
    };
  }
  var ent = new Asteroid.Entity(doc);
  this.components.forEach(function(component) {
    ent.entComps.push(new component(ent));
  });
  return ent;
};

EntityCollection.prototype.insert = function(doc) {
  var _id = this.collection.insert(ent.doc);
  var _id = doc._id || Random.id();
  if (doc == null) {
    doc = {
      _id: Random.id()
    };
  }
  var ent = new Asteroid.Entity(doc);
  this.components.forEach(function(component) {
    ent.entComps.push(new component(ent));
  });
  return ent;
};

EntityCollection.prototype.destroy = function() {
  this.handle.stop();
  for (var _id in this.entities) {
    this.removed(_id);
  }
};

// EntityCollection.prototype.add = function(ent) {
//   this.collection.insert(ent.doc);
//   this.subs.forEach(function(sub) {
//     sub.added(ent.doc._id, ent.doc);
//   });
//   return ent;
// };

EntityCollection.prototype.advance = function(delta) {
  for (var _id in this.entities) {
    this.entities[_id].advance(delta);
  }
  for (var _id in this.entities) {
    // We need to clone to ensure that the subscription updates.
    // TODO: Check if this workaround is still needed.
    var cloneDoc = JSON.parse(JSON.stringify(this.entities[_id].doc));
    this.subs.forEach(function(sub) {
      sub.changed(_id, cloneDoc);
    });
  }

  if (Meteor.isServer) {
    // Pick an entity at random and persist it back to the database.
    var entId = null;
    var count = 0;
    for (var _id in this.entities) {
      if (Math.random() <= 1 / ++count) {
        entId = _id;
      }
    }
    if (entId) {
      var ent = this.entities[entId];
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
