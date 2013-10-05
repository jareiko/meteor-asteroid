Asteroid
========

Asteroid gives [Meteor](http://www.meteor.com/)
an [Entity-Component-System](http://en.wikipedia.org/wiki/Entity_component_system)
with collection proxying.

Meteor is perfect for real-time games. Asteroid gets you started.

* Attach components (behaviors) to entities (documents)
* Perform simulation without updating the database every frame
* Client side prediction

Coming soon:

* Fine-grain publishing control, for example visible sets

This is very early code. Treat with caution.
Suggestions and pull reqs are most welcome!

Install
-------

Install with [Meteorite](https://github.com/oortcloud/meteorite/):

    mrt install asteroid

    meteor remove autopublish

Quick Start
-----------

    Ents = new Meteor.Collection("ents");

    myES = new Asteroid.EntitySystem("ents");

    myES.registerComponent("robot", {
      added: function() {
        // Start at the origin.
        this.pos = [ 0, 0 ]
      },
      update: function(delta) {
        // Move forward, exterminate!
        this.pos[0] += delta;
      }
    });

    myES.setCollection(Ents);

    myES.add("flying", "robot");

Docs
----

    new Asteroid.EntitySystem(name);

Creates an `EntitySystem` publishing to the `name` collection on the client.

This can be the same as the backing collection name, as in the quick start example.
You can also use a different name if you prefer.

    es.update(delta);

Performs a full update loop of the `EntitySystem`.
This should be called once per frame on the client to perform predictive simulation.

Currently, a 0.2s update interval will be set up automatically on the server.

    es.registerComponent(name, handlers);

Register a component called `name`. `handlers` is an object which may have the following methods:

    added: function() {}
    removed: function() {}
    update: function(delta) {}

These methods are called with the entity document bound as `this`.

    es.setCollection(collection);

`collection` is a Meteor.Collection instance.
This should be called after registering all components.

Notes
-----

Entities have a special field called `components` which is an array of strings.
For example, this entity:

    {
      "_id": "xyz',
      "components": [ "flying", "robot" ]
    }

will have its behavior controlled by the `flying` and `robot` components.

`EntitySystem` runs on both client and server, but the server is authoritative.

Update rate can be controlled independently on server and client.
Typically the client should update (predictively) once per frame, while the server will update
at a fixed interval.

Server-side updates are performed against an in-memory entity cache.
Data can be persisted back to the database at configurable intervals,
although currently Asteroid uses a random strategy.
Entity deletion always results in immediate removal from the database.
