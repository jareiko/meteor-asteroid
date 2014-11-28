// Write your tests here!
// Here is an example.
Tinytest.add('example', function (test) {
  test.equal(true, true);
});

Tinytest.add('simple', function(test) {
  var docs = new Meteor.Collection(null);
  var entColl = new Asteroid.EntityCollection(docs);
  entColl.add(entColl.create());
});

Tinytest.add('getComponent', function(test) {
  var docs = new Meteor.Collection(null);
  var entColl = new Asteroid.EntityCollection(docs);

  function TestComponent() {}

  var ent1 = entColl.add(entColl.create());

  test.isNull(ent1.getComponent(TestComponent));

  entColl.addComponent(TestComponent);
  var ent2 = entColl.add(entColl.create());
  console.log(ent1);
  console.log(ent2);
  console.log(entColl.entities);

  console.log(ent1.getComponent(TestComponent));
  test.instanceOf(ent1.getComponent(TestComponent), TestComponent);
  test.instanceOf(ent2.getComponent(TestComponent), TestComponent);
});

// advance the system, check that entity is advanced.
Tinytest.add('advance', function(test) {
  var docs = new Meteor.Collection(null);
  var entColl = new Asteroid.EntityCollection(docs);

  var MockComponent = function MockComponent() {
    return sinon.mock();
  };

  entColl.addComponent(MockComponent);
  var ent = entColl.add(entColl.create());

  // var mock = ent.getComponent(MockComponent);
  var mock = ent.entComps[0];

  mock.expect('advance').once();

  entColl.advance(1);

  mock.verify();
});
