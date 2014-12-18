Asteroid.EntitySystem = function EntitySystem(fps) {
  fps = (typeof fps !== 'undefined') ? fps : 60;
  this.collections = [];

  // TODO: Make advancing configurable.
  if (Meteor.isServer) {
    //less floating point errors in calculations
    fps = ( 1000 / (fps * 1000));
    var that = this;
    Meteor.setInterval(function() {
      that.advance(fps);
    }, fps * 1000);
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