// Write your tests here!
// Here is an example.
Tinytest.add('example', function (test) {
  test.equal(true, true);
});

Tinytest.add('simple', function(test) {
  var docs = new Meteor.Collection(null);
  var entColl = new Asteroid.EntityCollection(docs);
  var id1 = docs.insert({});
  test.length(_.keys(entColl.entities), 1);
});

Tinytest.add('getComponent', function(test) {
  var docs = new Meteor.Collection(null);
  var entColl = new Asteroid.EntityCollection(docs);

  function TestComponent() {}

  var id1 = docs.insert({});

  test.isNull(entColl.getEntityComponent(id1, TestComponent));

  entColl.addComponent(TestComponent);
  var id2 = docs.insert({});

  // Check that component has been added for both old and new documents.
  test.instanceOf(entColl.getEntityComponent(id1, TestComponent), TestComponent);
  test.instanceOf(entColl.getEntityComponent(id2, TestComponent), TestComponent);
});

// advance the system, check that entity is advanced.
Tinytest.add('advance', function(test) {
  var docs = new Meteor.Collection(null);
  var entColl = new Asteroid.EntityCollection(docs);

  function MockComponent() {
    this.advance = sinon.spy();
  }

  entColl.addComponent(MockComponent);
  var id1 = docs.insert({});

  entColl.advance(3);

  var mock = entColl.getEntityComponent(id1, MockComponent);
  test.equal(mock.advance.callCount, 1);
  test.equal(mock.advance.args[0][0], 3);
});
