Asteroid
========

Asteroid is a real-time multiplayer game framework built on [Meteor](http://www.meteor.com/).

It provides an [Entity-Component-System](http://en.wikipedia.org/wiki/Entity_component_system)
with collection proxying.

* Attach components (behaviors) to entities (documents)
* Perform logic without updating the database every frame
* Run the same logic on the client for prediction

Future development:

* Front-end bindings for Three.js & Pixi.js
* Fine-grain publishing control, so we don't send all data to all clients

This is alpha code.
Feedback is welcome!

Install
-------

Install Asteroid:

    $ meteor add jareiko:asteroid

If you want to use the same collection name for entities on client and server,
you'll need to remove the `autopublish` and `insecure` packages:

    $ meteor remove autopublish insecure

Examples
--------

    BotDocs = new Meteor.Collection("bots");

    Bots = new Asteroid.EntityCollection(BotDocs);

    function BotComponent(ent) {
      this.doc = ent.doc;
    }

    BotComponent.prototype.advance = function(delta) {
      // Move forward!
      this.doc.pos[0] += delta;
    };

    Bots.addComponent(Asteroid.Transform);  // A built-in component.
    Bots.addComponent(BotComponent);

    // An EntitySystem will call advance() automatically on the server.
    myES = new Asteroid.EntitySystem();
    myES.addEntityCollection(Bots);

    Bots.add(Bots.create());

Details
-------

### Asteroid.Entity

These are constructed by `EntityCollection.create()`.

### Asteroid.EntityCollection

    new Asteroid.EntityCollection(name);

Creates an `EntityCollection` publishing to the `name` collection on the client.

This can be the same as the backing collection name, as in the quick start example.
You can also use a different name if you prefer.

    entityCollection.advance(delta);

Advance `EntityCollection` state by `delta` seconds.
This should be called once per frame on the client to perform predictive simulation.

When attached to an `EntitySystem`, a 0.1s advance interval will be set up automatically on the server.

    entityCollection.addComponent(constructor);

Add a component to this collection. Each document will have a component instance
created for it via `new constructor()`.

Components may have the following methods:

    component.advance(delta);  # Called to perform regular update logic.
    component.removed();       # Notifies the component that its entity has been destroyed.

    ec.create();

Create a new entity and return its document.

In future this may return some kind of Entity type which wraps the document and its
corresponding component instances.

    ec.getComponent(constructor, _id);

Return the matching component instance for the entity with the given `_id`.

You need to pass a reference to the same constructor function as was passed to
`addComponent`. In future it may be possible to assign names to components for
easier access.

### Asteroid.EntitySystem

    new Asteroid.EntitySystem();

Creates an `EntitySystem`, which manages `EntityCollection`s.

    entitySystem.addEntityCollection(entityCollection);

Attach an `EntityCollection`.

    entitySystem.advance(delta);

Calls `advance` on all attached `EntityCollection`s.

On the server, this will be called automatically every 0.1s.
This is not yet configurable.

Notes
-----

Entities are simulated on both client and server, but the server is authoritative.

Any data that should be persisted to the DB or published to the client should
be included in the entity document. Components may maintain their own state
outside of the document, but it will be lost on page reloads or server restarts.

Client-driven changes to entity state, such as controlling a game character,
should be made via Meteor [Methods](http://docs.meteor.com/#methods_header).

Advance rate can be different on server and client.
Typically the client should call es.advance once per frame for smooth animation,
while the server will advance at a fixed interval.

`EntityCollection` maintains an in-memory entity cache.
On the server, this data can be persisted back to the database at configurable intervals,
although currently Asteroid uses a random strategy.
Entity deletion always results in immediate removal from the database.

Change log
----------

### 0.7.0

* Switch to JavaScript instead of CoffeeScript
