Package.describe({
  summary: "Entity-component-system (ECS) and collection proxying for real-time games."
});

Package.onUse(function (api, where) {
  api.export('Asteroid');
  api.add_files('entity.js');
  api.add_files('entitycollection.js');
  api.add_files('entitysystem.js');
  api.add_files('components.js');
});
