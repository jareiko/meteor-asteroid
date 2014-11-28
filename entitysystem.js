Asteroid.EntitySystem = function EntitySystem() {
  var delta;
  this.collections = [];

  // TODO: Make advancing configurable.
  if (Meteor.isServer) {
    delta = 0.1;
    var that = this;
    Meteor.setInterval(function() {
      that.advance(delta);
    }, delta * 1000);
  }
};

Asteroid.EntitySystem.prototype.addEntityCollection = function(collection) {
  this.collections.push(collection);
};

Asteroid.EntitySystem.prototype.advance = function(delta) {
  this.collections.forEach(function(collection) {
    collection.advance(delta);
  });
};
