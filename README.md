Asteroid
========

Asteroid is a real-time multiplayer game framework built on [Meteor](http://www.meteor.com/).

It provides an [Entity-Component-System](http://en.wikipedia.org/wiki/Entity_component_system)
with collection proxying.

* Attach components (behaviors) to entities (documents)
* Perform logic without updating the database every frame
* Run the same logic on the client for prediction

Coming soon:

* Front-end bindings for Three.js & Pixi.js
* Fine-grain publishing control, so we don't send all data to all clients
* JavaScript instead of CoffeeScript

This is very early code.
Every aspect is open to discussion!

Install
-------

Install Meteor and [Meteorite](https://github.com/oortcloud/meteorite/) if necessary:

    $ curl https://install.meteor.com | /bin/sh
    $ npm install -g meteorite

Create an app:

    $ meteor create myapp
    $ cd myapp

If you want to use the same collection name for entities on client and server,
you'll need to remove the `autopublish` and `insecure` packages:

    $ meteor remove autopublish insecure

Install Asteroid:

    $ mrt install asteroid


Quick Start
-----------

    Ents = new Meteor.Collection("ents");

    myES = new Asteroid.EntitySystem("ents");

    myES.registerComponent("robot", {
      added: function(ent, params) {
        if (params) this.name = params.name;
      },
      advance: function(ent, delta) {
        // Move forward!
        ent.componentData('transform').pos[0] += delta;
      }
    });

    myES.setCollection(Ents);

    myES.createEntity({ robot: { name: "R2-D2" } });

Details
-------

    new Asteroid.EntitySystem(name);

Creates an `EntitySystem` publishing to the `name` collection on the client.

This can be the same as the backing collection name, as in the quick start example.
You can also use a different name if you prefer.

    es.advance(delta);

Advance `EntitySystem` state by `delta` seconds.
This should be called once per frame on the client to perform predictive simulation.

Currently, a 0.2s advance interval will be set up automatically on the server.

    es.registerComponent(name, handlers);

Register a component called `name`. `handlers` is an object which may have
some or all of the following methods:

    created: function(ent) {}
    removed: function(ent) {}
    advance: function(ent, delta) {}
    publish: function(ent) {}

These methods are called with the component field bound as `this`
and the entire entity document passed as `ent`.

`publish` is called after each advance cycle on the server.
It may return an object representing the component's state which will be
published to the client.
If it returns a falsy value then no action is taken.

    es.setCollection(collection);

`collection` is a Meteor.Collection instance.
This should be called after registering all components.
It will load all documents with `find()` and call `added()` on components as necessary.

    es.addEntity(components...);

Create a new entity with the named `components`.
For each component, an empty object with the same name will be added to the entity,
and the component's `added()` method will be called.

Currently, a default component `transform` is also added, which sets `pos: [ 0, 0, 0 ]`
by default, and publishes and persists this value.

Notes
-----

An entity's components are determined by its document fields.
For example, this entity:

    {
      "_id": "xyz',
      "transform": {
        pos: [ 0, 0, 0 ]
      },
      "flying": {},
      "robot": {}
    }

will have its behavior controlled by the `flying` and `robot` components.
`transform` is a built-in component which currently just creates a `pos` array.
Fields that do not correspond to any registered component (such as `_id`) are ignored.

`EntitySystem` runs on both client and server, but the server is authoritative.
Client-driven changes to entity state, such as controlling a game character,
should be made via Meteor's RPCs called "methods".

Advance rate can be controlled independently on server and client.
Typically the client should call es.advance once per frame for smooth animation,
while the server will advance at a fixed interval.

`EntitySystem` maintains an in-memory entity cache.
On the server, this data can be persisted back to the database at configurable intervals,
although currently Asteroid uses a random strategy.
Entity deletion always results in immediate removal from the database.
