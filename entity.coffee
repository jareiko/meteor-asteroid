
Asteroid = {}

class Asteroid.Entity
  constructor: (@doc) ->
    # This array must match the container's @components array for getComponent to work.
    # TODO: Use component names instead?
    @entComps = []
    # TODO: Pre-filter components into lists according to exposed methods.

  changed: (fields) ->
    # TODO: Remove fields that are marked as undefined.
    _.extend @doc, fields
    comp.changed? fields for comp in @entComps
    return

  removed: ->
    comp.removed?() for comp in @entComps
    return

  advance: (delta) ->
    comp.advance? delta for comp in @entComps
    return

  getComponent: (component) ->
    _.findWhere @entComps, constructor: component

class Asteroid.EntityCollection
  constructor: (@collection) ->
    @ents = {}
    @components = []
    @subs = []

    # TODO: Pass cursor separately, so that reduced views can be used.
    cursor = collection.find()
    # @handle = cursor.observeChanges observeChangesCache { @added, @changed, @removed }
    # @handle = cursor.observe { @added, @changed, @removed }
    @handle = cursor.observeChanges { @added, @changed, @removed }

  addComponent: (component) ->
    idx = @components.length
    @components.push component
    for id, ent of @ents
      ent.entComps[idx] = new component ent
    return

  destroy: ->
    @handle?.stop()
    @removed _id for _id of @ents
    return

  create: (doc) ->
    doc ?= { _id: Random.id() }
    ent = new Asteroid.Entity doc
    ent.entComps.push new component ent for component in @components
    ent

  add: (ent) ->
    @collection.insert ent.doc # if Meteor.isServer
    sub.added ent.doc._id, ent.doc for sub in @subs
    ent

  added: (_id, fields) =>
    # A document was added to the underlying collection, so create an Entity.
    ent = @ents[_id] = @create _.extend { _id }, fields
    sub.added _id, ent.doc for sub in @subs
    ent

  changed: (_id, fields) =>
    # On the server, we assume that any DB changes were probably
    # caused by us at some point in the past, so we ignore them.
    if Meteor.isClient
      @ents[_id].changed fields
      # TODO: Publish this change immediately, instead of waiting for advance?
      # sub.changed _id, doc for sub in @subs
    return

  removed: (_id) =>
    @ents[_id].removed()
    sub.removed _id for sub in @subs
    delete @ents[_id]
    return

  advance: (delta) ->
    ent.advance delta for _id, ent of @ents

    # Publish.
    for _id, ent of @ents
      # TODO: Check for actual changes!
      cloneDoc = JSON.parse JSON.stringify ent.doc
      sub.changed _id, cloneDoc for sub in @subs

    # Persist.
    if Meteor.isServer
      # TODO: Configurable strategies, eg round-robin.
      # TODO: Ignore unchanged ents.
      ent = null
      count = 0
      (ent = e; _id = i) for i, e of @ents when Math.random() <= 1 / ++count
      @collection.update { _id }, ent.doc if ent
    return

  publish: (collection, sub) ->
    boundSub =
      added: sub.added.bind sub, collection
      changed: sub.changed.bind sub, collection
      removed: sub.removed.bind sub, collection
    boundSub.added _id, ent.doc for _id, ent of @ents
    sub.ready()
    @subs.push boundSub
    return

class Asteroid.EntitySystem
  constructor: ->
    @collections = []

    if Meteor.isServer
      delta = 0.1
      Meteor.setInterval (=> @advance delta), delta * 1000

  addEntityCollection: (collection) ->
    @collections.push collection
    return

  advance: (delta) ->
    for collection in @collections
      collection.advance delta
    return
