
var callMethodOnComponents = function(components, method) {
  var args = [].slice.call(arguments, 2) || [];
  for (var _id in components) {
    var comp = components[_id];
    if (typeof comp[method] === 'function') {
      return comp[method].apply(obj, args);
    }
  }
};

var EntityCollection =
    Asteroid.EntityCollection = function EntityCollection(collection) {

  // The collection of entity documents.
  this.collection = collection;

  // An ordered list of components for this collection.
  this.components = [];

  // A cursor for the documents in the collection.
  // TODO: Allow passing in a custom cursor, eg to select a subset.
  this.cursor = collection.find();

  // Our entities, keyed by _id.
  // Each is an array tuple:
  //   [0]: The document, which can be updated independently of the backing collection.
  //   [1]: An array of component instances, corresponding to the components[] array.
  this.entities = {};

  // Subscriptions.
  this.subs = [];

  var entColl = this;
  this.handle = this.cursor.observeChanges({
    added: function(_id, fields) {
      var doc = _.extend({_id: _id}, fields);
      entColl.entities[_id] = [
        doc,
        entColl.components.map(function(component) {
          return new component(doc);
        })
      ];
      entColl.subs.forEach(function(sub) {
        sub.added(_id, doc);
      });
    },
    changed: function(_id, fields) {
      callMethodOnComponents(entColl.entities[_id], 'changed', fields);
    },
    removed: function(_id) {
      callMethodOnComponents(entColl.entities[_id], 'removed');
      entColl.subs.forEach(function(sub) {
        sub.removed(_id);
      });
      delete entColl.entities[_id];
    }
  });
};

EntityCollection.prototype.addComponent = function(component) {
  this.components.push(component);

  // Construct a new component instance for each existing entity.
  for (var _id in this.entities) {
    var entity = this.entities[id];
    entity[1].push(new component(entity[0]));
  });
};

EntityCollection.prototype.advance = function(delta) {
  for (var _id in this.entities) {
    callMethodOnComponents(this.entities[_id][1], 'advance', delta);
  }

  for (var _id in this.entities) {
    // TODO: Track which documents have actually changed.
    var doc = this.entities[_id][0];
    // We need to clone to ensure that the subscription updates.
    // TODO: Check if this workaround is still needed.
    var cloneDoc = JSON.parse(JSON.stringify(doc));
    this.subs.forEach(function(sub) {
      sub.changed(_id, cloneDoc);
    });
  });

  if (Meteor.isServer) {
    this.persistRandomly();
  }
};

EntityCollection.prototype.persistRandomly = function() {
  var persistId = null;
  var count = 0;
  for (var _id in this.entities) {
    if (Math.random() <= 1 / ++count) {
      persistId = _id;
    }
  }
  if (persistId) {
    this.collection.update(persistId, this.entities[persistId][0]);
  }
};

EntityCollection.prototype.publish = function(collection, sub) {
  var boundSub = {
    added: sub.added.bind(sub, collection),
    changed: sub.changed.bind(sub, collection),
    removed: sub.removed.bind(sub, collection)
  };
  for (var _id in this.entities) {
    boundSub.added(_id, this.entities[_id][0]);
  }
  sub.ready();
  this.subs.push(boundSub);
};

EntityCollection.prototype.findById = function(_id) {
  return this.entities[_id];
};
