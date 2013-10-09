
Asteroid = {}

# This cache guarantees that object identity will not change, and that
# references to documents will remain valid for the document's lifetime.
# It's possible that this is true of .observe() docs, but I can't be sure.
observeChangesCache = (callbacks) ->
  docs = []
  added: (_id, fields) ->
    doc = { _id }
    _.extend doc, fields
    docs[_id] = doc
    callbacks.added doc
  changed: (_id, fields) ->
    doc = _.extend docs[_id], fields
    # TODO: Pass old doc as second parameter?
    callbacks.changed doc
  removed: (_id) ->
    callbacks.removed docs[_id]
    delete docs[_id]

###
Component interface:

new constructor(doc): Component instance attached to entity.
changed(): Entity document has been changed by underlying data source.
removed(): Entity has been removed.
advance(delta): Time has passed.

What should you put in the document? Anything you want persisted or published.
###

# TODO: Introduce an Entity type which wraps a document and all its component instances.

class Asteroid.EntityCollection
  constructor: (@collection) ->
    @docs = {}

    # These are matching arrays.
    # TODO: Make them objects keyed by component name instead?
    @components = []
    @entComps = []

    @subs = []

    # TODO: Pass cursor separately, so that reduced views can be used.
    cursor = collection.find()
    # @handle = cursor.observeChanges observeChangesCache { @added, @changed, @removed }
    @handle = cursor.observe { @added, @changed, @removed }
    # TODO: Use observeChanges interface instead?

  addComponent: (component) ->
    name = @components.length
    @components.push component
    @entComps.push entComps = {}
    for id, ent of @docs
      entComps[id] = new component ent
    return

  destroy: ->
    @handle?.stop()
    @removed _id for _id of @docs
    return

  added: (doc) =>
    _id = doc._id
    @docs[_id] = doc #JSON.parse JSON.stringify doc
    for name, entComp of @entComps
      entComp[_id] = new @components[name] doc
    sub.added _id, doc for sub in @subs
    return

  changed: (newDoc, oldDoc) =>
    # Note that oldDoc is currently not provided by observeChangesCache.
    # On the server, we assume that any DB changes were probably
    # caused by us at some point in the past, so we ignore them.
    if Meteor.isClient
      _id = newDoc._id
      _.extend @docs[_id], newDoc
      for name, entComp of @entComps
        entComp[_id].changed?()
      # TODO: Publish this change immediately, instead of waiting for advance?
      # sub.changed _id, doc for sub in @subs
    return

  removed: (oldDoc) =>
    _id = oldDoc._id
    for name, entComp of @entComps
      entComp[_id].removed? oldDoc
      delete entComp[_id]
    sub.removed _id for sub in @subs
    delete @docs[_id]
    return

  advance: (delta) ->
    for name, entComp of @entComps
      for _id, comp of entComp
        comp.advance? delta

    # Publish.
    for sub in @subs
      for _id, doc of @docs
        # TODO: Check for actual changes!
        sub.changed _id, JSON.parse JSON.stringify doc

    # Persist.
    if Meteor.isServer
      # TODO: Configurable strategies, eg round-robin.
      # TODO: Ignore unchanged ents.
      doc = null
      count = 0
      for _id, d of @docs
        doc = d if Math.random() <= 1 / ++count
      @collection.update { _id: doc._id }, doc if doc
    return

  callMethod: (name, params...) ->
    for name, entComp of @entComps
      for _id, comp of entComp
        comp[name]? params...
    return

  publish: (collection, sub) ->
    boundSub =
      added: sub.added.bind sub, collection
      changed: sub.changed.bind sub, collection
      removed: sub.removed.bind sub, collection
    boundSub.added _id, doc for _id, doc of @docs
    sub.ready()
    @subs.push boundSub
    return

  create: ->
    doc = _id: Random.id()
    @added doc
    @collection.insert doc  # TODO: Only on server?
    doc

  getComponent: (component, _id) ->
    idx = @components.indexOf component
    return null if idx is -1
    @entComps[idx][_id]

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

  callMethod: (params...) ->
    for collection in @collections
      collection.callMethod params...
    return

###
class Asteroid.EntitySystemOld
  constructor: (@name) ->
    Asteroid.entSystems.push @

    # We maintain an in-memory cache of ents.
    @ents = []
    @entsById = {}

    # A list of subscriptions.
    # TODO: Move responsibility for publishing outside of EntitySystem.
    @subs = []

    # Registered components.
    @components = {}

    @collection = null

    if Meteor.isServer
      # TODO: Move responsibility for publishing outside of this class.
      entSys = @
      Meteor.publish 'region', (x, y) ->
        sub = @
        console.log "subscribe session: #{sub._session.id} user: #{sub.userId}"
        # TODO: Region limiting.
        sub.added name, ent._id, ent for ent in entSys.ents
        sub.ready()
        entSys.subs.push sub
        sub.onStop ->
          console.log "unsubscribe session: #{sub._session.id} user: #{sub.userId}"
          entSys.subs = _.without entSys.subs, sub
        return

    @defaultComponents = [ 'transform' ]

    @registerComponent 'transform',
      created: ->
        @pos = [ 0, 0, 0 ]
        @rot = 0
      publish: -> { @pos, @rot }

  _addEnt: (ent, initParams) ->
    throw new Error 'missing _id' unless ent._id
    @ents.push ent
    @entsById[ent._id] = ent
    for own field of ent
      @components[field]?.added?.call ent[field], ent, initParams?[field]
    sub.added @name, ent._id, ent for sub in @subs
    return

  _removeEnt: (_id) ->
    ent = @entsById[_id]
    return unless ent
    for own field of ent
      @components[field]?.removed?.call ent[field], ent
    @ents = _.filter @ents, (e) -> e._id isnt _id
    delete @entsById[_id]
    sub.removed @name, _id for sub in @subs
    return

  advance: (delta) ->
    ents = @ents
    subs = @subs
    components = @components

    for ent in ents
      for own field of ent
        components[field]?.advance?.call ent[field], ent, delta

    # for ent in ents
    #   for comp in ent.components
    #     components[comp]?.lateadvance?.call ent, delta

    # Clean up any destroyed ents.
    entsSnapshot = _.clone ents
    for ent in entsSnapshot
      if ent.destroyed
        removeEnt ent._id
        @collection.remove { _id: ent._id }

    # Publishing.
    if Meteor.isServer
      for ent in ents
        # TODO: More sophisticated rate limiting. :)
        # continue if Math.random() < 0.5

        publish = {}
        for own field of ent
          pub = components[field]?.publish?.call ent[field]
          publish[field] = pub if pub

        unless _.isEmpty publish
          # TODO: Maintain a cache and perform diffs?
          # It looks like Meteor is already doing this itself at the field level.

          # Workaround: Meteor seems to ignore changes unless you clone the object.
          publish = JSON.parse JSON.stringify publish

          for sub in subs
            # TODO: Check that this ent is visible to this sub.
            sub.changed @name, ent._id, publish

    # Persistence.
    if Meteor.isServer
      # TODO: Round-robin instead of random.
      # TODO: Ignore unchanged ents.
      ent = Random.choice ents
      @collection.update { _id: ent._id }, ent
    return

  registerComponent: (name, methods) ->
    @components[name] = methods
    for ent in @ents when ent[name]?
      methods.added?.call ent[name], ent
    return

  setCollection: (@collection) ->
    # For now we just grab everything.
    # This won't work once there are too many objects to fit in memory.
    handle = collection.find().observeChanges
      added: (_id, fields) =>
        ent = _.clone fields
        ent._id = _id
        @_addEnt ent
        return
      changed: (_id, fields) =>
        if Meteor.isClient
          # On the server, we assume that any DB changes were probably
          # caused by us at some point in the past, so we ignore them.
          ent = @entsById[_id]
          _.extend ent, fields if ent
        return
      removed: (_id) =>
        @_removeEnt _id
    return

  createEntity: (initParams = {}) ->
    components = Object.keys initParams
    components = _.union components, @defaultComponents
    ent =
      _id: Random.id()
    for field in components
      ent[field] = {}
    for field in components
      @components[field]?.created?.call ent[field], ent, initParams[field]
    @_addEnt ent, initParams
    @collection.insert ent
    ent

  findById: (id) -> @entsById[id]
###
